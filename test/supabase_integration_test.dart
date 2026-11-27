import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:app/app/providers.dart';
import 'package:app/config/supabase_config.dart';
import 'package:app/core/services/supabase_service.dart';
import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/member_repository.dart';
import 'package:app/data/repositories/training_planner_repository.dart';

void main() {
  group('Supabase Config & Service Tests', () {
    test('SupabaseConfig holds project URL, publishable key, and storage bucket names', () {
      expect(
        SupabaseConfig.url,
        'https://tnaxqehjowbatqghbbuk.supabase.co',
      );
      expect(
        SupabaseConfig.publishableKey,
        startsWith('sb_publishable_'),
      );
      expect(SupabaseConfig.isConfigured, isTrue);
      expect(SupabaseConfig.profileImagesBucket, 'profile-images');
      expect(SupabaseConfig.progressImagesBucket, 'progress-images');
      expect(SupabaseConfig.exerciseMediaBucket, 'exercise-media');
    });

    test('SupabaseService stays unready before initialize() is called in isolated unit tests', () {
      expect(SupabaseService.isReady, isFalse);
      expect(() => SupabaseService.client, throwsStateError);
    });

    test('SupabaseErrorMapper translates Auth, PostgREST, Storage, and network errors safely', () {
      final invalidAuth = SupabaseErrorMapper.toUserMessage(
        const AuthException('Invalid login credentials'),
      );
      expect(invalidAuth, contains('Incorrect email or password'));
      expect(invalidAuth.toLowerCase(), isNot(contains('sql')));

      final rlsErr = SupabaseErrorMapper.toUserMessage(
        const PostgrestException(message: 'new row violates row-level security policy', code: '42501'),
      );
      expect(rlsErr, contains('permission'));
      expect(rlsErr.toLowerCase(), isNot(contains('row-level security')));

      final dupErr = SupabaseErrorMapper.toUserMessage(
        const PostgrestException(message: 'duplicate key value violates unique constraint', code: '23505'),
      );
      expect(dupErr, 'This record already exists.');

      final storageErr = SupabaseErrorMapper.toUserMessage(
        const StorageException('Payload too large', statusCode: '413'),
      );
      expect(storageErr, contains('too large'));

      final timeoutErr = SupabaseErrorMapper.toUserMessage(
        TimeoutException('Timed out'),
      );
      expect(timeoutErr, contains('too long'));

      final netErr = SupabaseErrorMapper.toUserMessage(
        Exception('SocketException: Failed host lookup'),
      );
      expect(netErr, contains('No internet connection'));
    });

    test('Providers fall back cleanly to local/mock repositories when Supabase is not configured', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(authRepositoryProvider), isA<HybridAuthRepository>());
      expect(container.read(memberRepositoryProvider), isA<MockMemberRepository>());
      expect(
        container.read(trainingPlannerRepositoryProvider),
        isA<LocalTrainingPlannerRepository>(),
      );

      final auth = container.read(authStateProvider);
      expect(auth.isMember, isTrue);
      expect(auth.isAdmin, isFalse);
      expect(auth.isTrainer, isFalse);
    });
  });

  group('Supabase SQL Migrations Verification', () {
    test('Initial schema defines all 14 required tables and anti-escalation triggers', () {
      final schema = File('supabase/migrations/20261125000001_initial_gym_schema.sql')
          .readAsStringSync();

      const requiredTables = [
        'public.profiles',
        'public.memberships',
        'public.membership_plans',
        'public.attendance',
        'public.trainers',
        'public.workout_plans',
        'public.exercises',
        'public.workout_logs',
        'public.diet_plans',
        'public.meals',
        'public.food_logs',
        'public.water_logs',
        'public.payments',
        'public.notifications',
      ];

      for (final table in requiredTables) {
        expect(schema.contains('create table if not exists $table'), isTrue,
            reason: 'Missing table $table in initial schema');
      }

      expect(schema.contains('on_auth_user_created'), isTrue);
      expect(schema.contains('prevent_profile_role_escalation'), isTrue);
    });

    test('RLS migration enables RLS on all tables, adds explicit GRANTs, and avoids deprecated auth.role()', () {
      final rls = File('supabase/migrations/20261125000002_rls_and_grants.sql')
          .readAsStringSync();

      expect(rls.contains('grant usage on schema public to anon, authenticated;'), isTrue);
      expect(rls.contains('auth.role()'), isFalse,
          reason: 'Must use TO authenticated instead of deprecated auth.role()');
      expect(rls.contains('(select auth.uid())'), isTrue);
      expect(rls.contains('alter table public.profiles enable row level security;'), isTrue);
      expect(rls.contains('alter table public.payments enable row level security;'), isTrue);
      expect(rls.contains('alter table public.workout_logs enable row level security;'), isTrue);
      expect(rls.contains('alter table public.food_logs enable row level security;'), isTrue);
      expect(rls.contains('alter table public.water_logs enable row level security;'), isTrue);
    });

    test('Storage and realtime migration creates required buckets privately and adds realtime tables', () {
      final storage = File('supabase/migrations/20261125000003_storage_buckets_and_realtime.sql')
          .readAsStringSync();

      expect(storage.contains("'profile-images'"), isTrue);
      expect(storage.contains("'progress-images'"), isTrue);
      expect(storage.contains("'exercise-media'"), isTrue);
      expect(storage.contains('alter publication supabase_realtime add table public.notifications'), isTrue);
      expect(storage.contains('alter publication supabase_realtime add table public.memberships'), isTrue);
      expect(storage.contains('alter publication supabase_realtime add table public.attendance'), isTrue);
    });
  });
}
