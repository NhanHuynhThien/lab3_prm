import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../models/cloud_ledger.dart';
import '../models/ledger.dart';
import 'firestore_ledger_store.dart';
import 'ledger_validation.dart';
import 'reporting_calendar.dart';

/// Cloud envelope v1; domain payload remains local schema2, without local seeding.
abstract final class FirestoreLedgerCodec {
  static String segment(String value) {
    if (value.trim().isEmpty ||
        value == '.' ||
        value == '..' ||
        value.contains('/') ||
        RegExp(r'[\x00-\x1f]').hasMatch(value) ||
        utf8.encode(value).length > 1500 ||
        RegExp(r'^__.*__$').hasMatch(value)) {
      throw ArgumentError('ID không hợp lệ.');
    }
    return value;
  }

  static String quotaId(String accountId, String windowKey) => sha256
      .convert(utf8.encode('${segment(accountId)}\n$windowKey'))
      .toString();

  static CloudMap accountPayload(AIAccount value) {
    LedgerValidation.account(value);
    if (value.quotaWindows.isNotEmpty) {
      throw ArgumentError('Quota cloud phải lưu riêng qua quota_windows.');
    }
    return value.toJson()
      ..remove('quotaWindows')
      ..['currency'] = 'USD';
  }

  static CloudMap usagePayload(UsageSession value, {DateTime? now}) {
    LedgerValidation.usage(value, now: now);
    return {...value.toJson(), 'currency': 'USD'};
  }

  static CloudMap quotaPayload(AccountQuota value, {DateTime? now}) {
    segment(value.accountId);
    LedgerValidation.quota(value.snapshot, now: now);
    return {'accountId': value.accountId, ...value.snapshot.toJson()};
  }

  static CloudMap toFirestore(CloudMap payload) => {
    for (final entry in payload.entries)
      entry.key: switch (entry.key) {
        'createdAt' || 'occurredAt' || 'observedAt' || 'resetAt' =>
          Timestamp.fromDate(DateTime.parse(entry.value as String).toUtc()),
        _ => entry.value,
      },
  };

  static CloudMap _payload(CloudMap doc) {
    final raw = Map<String, dynamic>.from(doc['payload'] as Map);
    return {
      for (final entry in raw.entries)
        entry.key: switch (entry.key) {
          'createdAt' || 'occurredAt' || 'observedAt' || 'resetAt' =>
            (entry.value as Timestamp).toDate().toUtc().toIso8601String(),
          _ => entry.value,
        },
    };
  }

  static int counter(CloudMap doc, String key) {
    final value = doc[key];
    if (value is! int ||
        value < 0 ||
        value > LedgerValidation.maxExactInteger) {
      throw const FormatException('Counter không hợp lệ.');
    }
    return value;
  }

  static void _keys(CloudMap value, Set<String> expected) {
    if (value.length != expected.length ||
        !value.keys.every(expected.contains)) {
      throw const FormatException('Schema fields không hợp lệ.');
    }
  }

  static CloudRecord<T> decode<T>(
    String id,
    CloudMap doc,
    String ownerId,
    T Function(CloudMap) parse, {
    bool account = false,
    bool pending = false,
  }) {
    segment(id);
    _keys(doc, {
      'ownerId',
      'schemaVersion',
      'revision',
      'createdAt',
      'updatedAt',
      'payload',
      'lastOperationId',
      if (account) ...{
        'usageCount',
        'quotaCount',
        'lastUsageMutationId',
        'lastQuotaMutationId',
      },
    });
    if (doc['ownerId'] != ownerId ||
        doc['schemaVersion'] is! int ||
        doc['schemaVersion'] != 1 ||
        doc['revision'] is! int ||
        (doc['revision'] as int) < 1 ||
        (doc['revision'] as int) > LedgerValidation.maxExactInteger) {
      throw const FormatException('Owner/schema/revision không hợp lệ.');
    }
    DateTime? timestamp(String field) {
      if (pending && doc[field] == null) return null;
      return (doc[field] as Timestamp).toDate().toUtc();
    }

    segment(doc['lastOperationId'] as String);

    return CloudRecord(
      id: id,
      ownerId: ownerId,
      value: parse(_payload(doc)),
      revision: doc['revision'] as int,
      createdAt: timestamp('createdAt'),
      updatedAt: timestamp('updatedAt'),
      usageCount: account ? counter(doc, 'usageCount') : 0,
      quotaCount: account ? counter(doc, 'quotaCount') : 0,
    );
  }

  static CloudRecord<CloudSettings> settings(
    String id,
    CloudMap doc,
    String uid, {
    bool pending = false,
  }) => decode(id, doc, uid, (payload) {
    if (id != 'reporting') throw const FormatException('Settings ID');
    _keys(payload, {'reportingTimezone'});
    final zone = payload['reportingTimezone'] as String;
    ReportingCalendar.validateZone(zone);
    return CloudSettings(zone);
  }, pending: pending);

  static CloudRecord<AIAccount> account(
    String id,
    CloudMap doc,
    String uid, {
    bool pending = false,
  }) => decode(
    id,
    doc,
    uid,
    (payload) {
      final value = AIAccount.fromJson({...payload, 'quotaWindows': []});
      if (payload['currency'] != 'USD') throw const FormatException('Currency');
      _keys(payload, accountPayload(value).keys.toSet());
      if (value.id != id) throw const FormatException('Account ID mismatch');
      for (final key in ['lastUsageMutationId', 'lastQuotaMutationId']) {
        if (doc[key] != null) segment(doc[key] as String);
      }
      return value;
    },
    account: true,
    pending: pending,
  );

  static CloudRecord<UsageSession> usage(
    String id,
    CloudMap doc,
    String uid, {
    bool pending = false,
  }) => decode(id, doc, uid, (payload) {
    final value = UsageSession.fromJson(payload);
    if (payload['currency'] != 'USD') throw const FormatException('Currency');
    _keys(payload, usagePayload(value).keys.toSet());
    if (value.id != id) throw const FormatException('Usage ID mismatch');
    segment(value.accountId);
    return value;
  }, pending: pending);

  static CloudRecord<AccountQuota> quota(
    String id,
    CloudMap doc,
    String uid, {
    bool pending = false,
  }) => decode(id, doc, uid, (payload) {
    final accountId = payload['accountId'] as String;
    final value = AccountQuota(
      accountId: accountId,
      snapshot: QuotaSnapshot.fromJson(payload),
    );
    _keys(payload, quotaPayload(value).keys.toSet());
    if (quotaId(accountId, value.snapshot.windowKey) != id) {
      throw const FormatException('Quota ID mismatch');
    }
    return value;
  }, pending: pending);
}
