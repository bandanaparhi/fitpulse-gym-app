import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/announcement.dart';
import '../models/class_booking.dart';
import '../models/faq_item.dart';
import '../models/gym_class.dart';
import '../models/gym_contact_info.dart';
import '../models/notification_item.dart';
import '../models/notification_preferences.dart';
import '../models/payment.dart';
import '../models/support_feedback.dart';
import '../models/trainer.dart';
import '../models/training_session.dart';
import '../models/workout.dart';
import 'class_repository.dart';
import 'payment_repository.dart';
import 'settings_repository.dart';
import 'support_repository.dart';
import 'trainer_repository.dart';
import 'supabase_workout_repository.dart';

/// Supabase-backed [ClassRepository].
class SupabaseClassRepository implements ClassRepository {
  SupabaseClient get _client => SupabaseService.client;

  GymClass _mapClass(Map<String, dynamic> r) => GymClass(
        id: r['id'] as String,
        title: (r['title'] as String?) ?? '',
        description: (r['description'] as String?) ?? '',
        trainerName: (r['trainer_name'] as String?) ?? '',
        room: (r['room'] as String?) ?? '',
        startTime: DateTime.tryParse('${r['start_time']}') ?? DateTime.now(),
        durationMinutes: (r['duration_minutes'] as int?) ?? 45,
        capacity: (r['capacity'] as int?) ?? 20,
        bookedCount: (r['booked_count'] as int?) ?? 0,
        category: (r['category'] as String?) ?? 'Fitness',
        difficulty: (r['level'] as String?) ?? 'All Levels',
      );

  @override
  Future<List<GymClass>> getUpcomingClasses() async {
    try {
      final rows = await _client
          .from('gym_classes')
          .select()
          .eq('is_active', true)
          .order('start_time', ascending: true);
      return rows.map(_mapClass).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<GymClass?> getClassById(String classId) async {
    try {
      final row = await _client
          .from('gym_classes')
          .select()
          .eq('id', classId)
          .maybeSingle();
      return row == null ? null : _mapClass(row);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<List<ClassBooking>> getMemberBookings(String memberId) async {
    try {
      final rows = await _client
          .from('class_bookings')
          .select('*, gym_classes(title, start_time, trainer_name, room, duration_minutes)')
          .eq('user_id', memberId)
          .order('booked_at', ascending: false);

      return rows.map((r) {
        final cls = r['gym_classes'] as Map<String, dynamic>? ?? const {};
        return ClassBooking(
          id: r['id'] as String,
          classId: r['class_id'] as String,
          className: (cls['title'] as String?) ?? 'Class',
          memberId: r['user_id'] as String,
          classStartTime:
              DateTime.tryParse('${cls['start_time']}') ?? DateTime.now(),
          bookedAt: DateTime.tryParse('${r['booked_at']}') ?? DateTime.now(),
          status: (r['status'] as String?) ?? 'Confirmed',
          trainerName: (cls['trainer_name'] as String?) ?? '',
          room: (cls['room'] as String?) ?? '',
          durationMinutes: (cls['duration_minutes'] as int?) ?? 45,
        );
      }).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<bool> bookClass(String memberId, String classId) async {
    try {
      final existing = await _client
          .from('class_bookings')
          .select('id')
          .eq('user_id', memberId)
          .eq('class_id', classId)
          .eq('status', 'Confirmed')
          .maybeSingle();
      if (existing != null) return false;

      await _client.from('class_bookings').insert({
        'user_id': memberId,
        'class_id': classId,
        'status': 'Confirmed',
      });
      return true;
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<bool> cancelBooking(String bookingId) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return false;
      await _client
          .from('class_bookings')
          .update({'status': 'Cancelled'})
          .eq('id', bookingId)
          .eq('user_id', uid);
      return true;
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }
}

/// Supabase-backed [TrainerRepository].
class SupabaseTrainerRepository implements TrainerRepository {
  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<Trainer?> getTrainerForMember(String memberId) async {
    try {
      final rows = await _client
          .from('trainer_assignments')
          .select('trainers(*)')
          .eq('member_id', memberId)
          .eq('is_active', true)
          .limit(1);

      if (rows.isEmpty) return null;
      final t = rows.first['trainers'] as Map<String, dynamic>?;
      if (t == null) return null;
      return Trainer(
        id: t['id'] as String,
        name: (t['full_name'] as String?) ?? '',
        specialty: (t['specialization'] as String?) ?? '',
        bio: (t['bio'] as String?) ?? '',
        photoUrl: t['profile_image'] as String?,
        rating: (t['rating'] as num?)?.toDouble() ?? 5.0,
        totalClients: 0,
        phone: '',
        email: '',
        qualifications:
            List<String>.from(t['certifications'] as List? ?? const []),
      );
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<List<TrainingSession>> getTrainingSessions(String memberId) async {
    try {
      final rows = await _client
          .from('training_sessions')
          .select('*, trainers(full_name)')
          .eq('user_id', memberId)
          .order('scheduled_at', ascending: true);

      return rows.map((r) {
        final t = r['trainers'] as Map<String, dynamic>?;
        return TrainingSession(
          id: r['id'] as String,
          trainerId: r['trainer_id'] as String,
          trainerName: (t?['full_name'] as String?) ?? 'Trainer',
          memberId: r['user_id'] as String,
          sessionTitle: (r['title'] as String?) ?? '1-on-1 Coaching',
          sessionDate:
              DateTime.tryParse('${r['scheduled_at']}') ?? DateTime.now(),
          durationMinutes: (r['duration_minutes'] as int?) ?? 60,
          location: (r['location'] as String?) ?? 'Main Gym Floor',
          status: (r['status'] as String?) ?? 'Scheduled',
          notes: r['notes'] as String?,
        );
      }).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<List<Workout>> getAssignedWorkouts(String memberId) {
    return SupabaseWorkoutRepository().getWorkouts(memberId);
  }

  @override
  Future<bool> sendTrainerMessage({
    required String trainerId,
    required String memberId,
    required String message,
  }) async {
    try {
      await _client.from('trainer_messages').insert({
        'trainer_id': trainerId,
        'user_id': memberId,
        'sender_role': 'member',
        'message': message.trim(),
      });
      return true;
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<bool> cancelSession(String sessionId) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return false;
      await _client
          .from('training_sessions')
          .update({'status': 'Cancelled'})
          .eq('id', sessionId)
          .eq('user_id', uid);
      return true;
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }
}

/// Supabase-backed [PaymentRepository] reading strictly verified `public.payments`
/// ledger rows (never storing card numbers, CVV, or banking passwords).
class SupabasePaymentRepository implements PaymentRepository {
  SupabaseClient get _client => SupabaseService.client;

  Payment _mapPayment(Map<String, dynamic> r) => Payment(
        id: r['id'] as String,
        memberId: r['user_id'] as String,
        amount: (r['amount'] as num).toDouble(),
        date: DateTime.tryParse('${r['paid_at'] ?? r['created_at']}') ??
            DateTime.now(),
        status: (r['payment_status'] as String?) ?? 'Paid',
        paymentMethod: (r['payment_method'] as String?) ?? 'Front Desk',
        invoiceNumber:
            (r['invoice_number'] as String?) ?? (r['transaction_reference'] as String? ?? ''),
        description: (r['description'] as String?) ?? '',
        serviceName: (r['service_name'] as String?) ?? '',
        subtotal: (r['subtotal'] as num?)?.toDouble(),
        taxAmount: (r['tax_amount'] as num?)?.toDouble(),
      );

  @override
  Future<List<Payment>> getPaymentHistory(String memberId) async {
    try {
      final rows = await _client
          .from('payments')
          .select()
          .eq('user_id', memberId)
          .order('created_at', ascending: false)
          .limit(50);
      return rows.map(_mapPayment).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<Payment?> getPaymentById(String paymentId) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return null;
      final row = await _client
          .from('payments')
          .select()
          .eq('id', paymentId)
          .eq('user_id', uid)
          .maybeSingle();
      return row == null ? null : _mapPayment(row);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<double> getPendingBalance(String memberId) async {
    try {
      final rows = await _client
          .from('payments')
          .select('amount')
          .eq('user_id', memberId)
          .eq('payment_status', 'Pending');
      double total = 0;
      for (final r in rows) {
        total += (r['amount'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  bool isOnlinePaymentConfigured() => false;
}

/// Supabase-backed [SettingsRepository].
class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return const NotificationPreferences();
      final row = await _client
          .from('notification_preferences')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return const NotificationPreferences();
      bool waterReminders = true;
      bool dietReminders = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('fitpulse_extra_notif_prefs_$uid');
        if (raw != null && raw.isNotEmpty) {
          final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          waterReminders = m['waterIntakeReminders'] as bool? ?? true;
          dietReminders = m['dietReminders'] as bool? ?? true;
        }
      } catch (_) {}
      return NotificationPreferences(
        membershipReminders: (row['membership_reminders'] as bool?) ?? true,
        paymentReminders: (row['payment_reminders'] as bool?) ?? true,
        workoutReminders: (row['workout_reminders'] as bool?) ?? true,
        waterIntakeReminders: waterReminders,
        dietReminders: dietReminders,
        classReminders: (row['class_reminders'] as bool?) ?? true,
        gymAnnouncements: (row['gym_announcements'] as bool?) ?? true,
      );
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw StateError('Your session has expired. Please sign in again.');
      }
      await _client.from('notification_preferences').upsert({
        'user_id': uid,
        'membership_reminders': preferences.membershipReminders,
        'payment_reminders': preferences.paymentReminders,
        'workout_reminders': preferences.workoutReminders,
        'class_reminders': preferences.classReminders,
        'gym_announcements': preferences.gymAnnouncements,
      }, onConflict: 'user_id');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'fitpulse_extra_notif_prefs_$uid',
          jsonEncode({
            'waterIntakeReminders': preferences.waterIntakeReminders,
            'dietReminders': preferences.dietReminders,
          }),
        );
      } catch (_) {}
      return preferences;
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }
}

/// Supabase-backed [SupportRepository] storing feedback/issue reports in
/// `public.support_feedback` while preserving grounded FAQ/contact info.
class SupabaseSupportRepository implements SupportRepository {
  final MockSupportRepository _faqFallback = MockSupportRepository(latency: Duration.zero);
  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<List<FaqItem>> getFaqs({String? category, String? searchQuery}) {
    return _faqFallback.getFaqs(category: category, searchQuery: searchQuery);
  }

  @override
  Future<GymContactInfo> getContactInfo() {
    return _faqFallback.getContactInfo();
  }

  @override
  Future<SupportFeedback> submitFeedback({
    required String memberId,
    required String category,
    required String subject,
    required String message,
    String type = 'feedback',
  }) async {
    try {
      final row = await _client
          .from('support_feedback')
          .insert({
            'user_id': memberId,
            'category': category,
            'subject': subject.trim(),
            'message': message.trim(),
            'is_issue_report': type == 'issue',
            'status': 'Open',
          })
          .select()
          .single();

      return SupportFeedback(
        id: row['id'] as String,
        memberId: memberId,
        category: category,
        subject: subject.trim(),
        message: message.trim(),
        type: type,
        createdAt: DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
        status: (row['status'] as String?) ?? 'Open',
      );
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<List<SupportFeedback>> getMemberSubmissions(String memberId) async {
    try {
      final rows = await _client
          .from('support_feedback')
          .select()
          .eq('user_id', memberId)
          .order('created_at', ascending: false);

      return rows.map((r) {
        return SupportFeedback(
          id: r['id'] as String,
          memberId: r['user_id'] as String,
          category: (r['category'] as String?) ?? '',
          subject: (r['subject'] as String?) ?? '',
          message: (r['message'] as String?) ?? '',
          type: (r['is_issue_report'] == true) ? 'issue' : 'feedback',
          createdAt: DateTime.tryParse('${r['created_at']}') ?? DateTime.now(),
          status: (r['status'] as String?) ?? 'Open',
        );
      }).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }
}

/// Supabase-backed service for member `notifications`, public `announcements`,
/// and nutrition `food_logs` / `water_logs`.
class SupabaseNotificationAndNutritionService {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<NotificationItem>> getNotifications(String memberId) async {
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .or('user_id.eq.$memberId,and(user_id.is.null,is_published.eq.true)')
          .order('created_at', ascending: false)
          .limit(50);

      return rows.map((r) {
        return NotificationItem(
          id: r['id'] as String,
          title: (r['title'] as String?) ?? '',
          message: (r['message'] as String?) ?? '',
          timestamp: DateTime.tryParse('${r['created_at']}') ?? DateTime.now(),
          isRead: (r['is_read'] as bool?) ?? false,
          type: (r['notification_type'] as String?) ?? 'announcement',
          actionRoute: r['action_route'] as String?,
          actionLabel: r['action_label'] as String?,
        );
      }).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<void> markAsRead(String notificationId, String memberId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', memberId);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<List<Announcement>> getPublishedAnnouncements() async {
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .isFilter('user_id', null)
          .eq('is_published', true)
          .order('created_at', ascending: false);

      return rows.map((r) {
        final msg = (r['message'] as String?) ?? '';
        return Announcement(
          id: r['id'] as String,
          title: (r['title'] as String?) ?? '',
          content: msg,
          shortDescription: msg.length > 100 ? '${msg.substring(0, 97)}...' : msg,
          date: DateTime.tryParse('${r['created_at']}') ?? DateTime.now(),
          author: 'FitPulse Administration',
          category: (r['notification_type'] as String?) ?? 'General',
          priority: 'Normal',
          isPublished: true,
        );
      }).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<void> logFoodEntry({
    required String userId,
    String? mealId,
    required String foodName,
    required String quantity,
    required int calories,
    required double protein,
    required double carbohydrates,
    required double fat,
  }) async {
    try {
      await _client.from('food_logs').insert({
        'user_id': userId,
        'meal_id': ?mealId,
        'food_name': foodName.trim(),
        'quantity': quantity.trim(),
        'calories': calories,
        'protein': protein,
        'carbohydrates': carbohydrates,
        'fat': fat,
        'consumed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<void> logWaterIntake({
    required String userId,
    required int quantityMl,
  }) async {
    try {
      await _client.from('water_logs').insert({
        'user_id': userId,
        'quantity_ml': quantityMl,
        'logged_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }
}
