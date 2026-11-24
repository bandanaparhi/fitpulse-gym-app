import '../models/faq_item.dart';
import '../models/gym_contact_info.dart';
import '../models/support_feedback.dart';

/// Abstract contract for Help and Support operations.
abstract class SupportRepository {
  Future<List<FaqItem>> getFaqs({String? category, String? searchQuery});
  Future<GymContactInfo> getContactInfo();
  Future<SupportFeedback> submitFeedback({
    required String memberId,
    required String category,
    required String subject,
    required String message,
    String type = 'feedback',
  });
  Future<List<SupportFeedback>> getMemberSubmissions(String memberId);
}

/// Centralized Mock Implementation of SupportRepository.
class MockSupportRepository implements SupportRepository {
  final Duration latency;

  MockSupportRepository({this.latency = const Duration(milliseconds: 150)});

  static const List<FaqItem> _officialFaqs = [
    FaqItem(
      id: 'FAQ-101',
      question: 'How do I check in to the gym facility?',
      answer:
          'Open the Attendance section in the app at /attendance to view your attendance history and check-in times. Present your Member ID (GM-1024) at the front desk reception scanner upon entry.',
      category: 'Facility & Access',
    ),
    FaqItem(
      id: 'FAQ-102',
      question: 'What are the gym operating and staffed hours?',
      answer:
          'Our facility is open and staffed Monday through Saturday from 6:00 AM to 10:00 PM, and Sundays from 7:00 AM to 2:00 PM. Access outside these hours is restricted for facility maintenance.',
      category: 'Facility & Access',
    ),
    FaqItem(
      id: 'FAQ-201',
      question: 'How do I book a group fitness class?',
      answer:
          'Navigate to Classes & Bookings at /classes. Browse available sessions, filter by category or date, and tap "Book Class" to secure your seat. You can view your active bookings under "My Bookings".',
      category: 'Classes & Bookings',
    ),
    FaqItem(
      id: 'FAQ-202',
      question: 'How can I cancel a class booking if I cannot attend?',
      answer:
          'Open the "My Bookings" tab at /classes/bookings and tap "Cancel Booking" on your upcoming class. Cancellations update class capacity immediately so waitlisted members can participate.',
      category: 'Classes & Bookings',
    ),
    FaqItem(
      id: 'FAQ-301',
      question: 'Where do I find my assigned workout routine and exercises?',
      answer:
          'Go to the Workouts section at /workouts. You will find your assigned training plan, weekly workout schedule, exercise breakdown with target sets and repetitions, and historical workout completions.',
      category: 'Workouts & Training',
    ),
    FaqItem(
      id: 'FAQ-302',
      question: 'How do I contact my assigned personal trainer?',
      answer:
          'Visit the My Trainer screen at /trainer. You can view your trainer Jordan Lee\'s credentials, upcoming scheduled 1-on-1 sessions, and tap "Contact Trainer" to send an in-app message.',
      category: 'Workouts & Training',
    ),
    FaqItem(
      id: 'FAQ-401',
      question: 'Where can I view my membership plan and renewal date?',
      answer:
          'Navigate to the Membership screen at /membership. Your active tier, membership expiration date (December 30, 2026), and plan renewal options are managed there.',
      category: 'Billing & Accounts',
    ),
    FaqItem(
      id: 'FAQ-402',
      question: 'Where do I find payment records and official receipts?',
      answer:
          'All verified payment records, pending payment balances, and downloadable PDF receipts with tax invoice breakdowns are available in the Payments section at /payments.',
      category: 'Billing & Accounts',
    ),
  ];

  static const GymContactInfo _defaultContactInfo = GymContactInfo(
    gymName: 'FitPulse Gym',
    email: 'support@fitpulse.com',
    phone: null, // Phone support intentionally null to illustrate unavailable channel messaging
    address: 'FitPulse Fitness Hub, Sector 42, Bengaluru, Karnataka 560001',
    operatingHours: 'Mon–Sat: 6:00 AM – 10:00 PM | Sun: 7:00 AM – 2:00 PM',
    assignedTrainerName: 'Jordan Lee',
    assignedTrainerEmail: 'jordan.lee@fitpulse.com',
  );

  final List<SupportFeedback> _submissions = [];

  @override
  Future<List<FaqItem>> getFaqs({String? category, String? searchQuery}) async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }

    var list = List<FaqItem>.from(_officialFaqs);

    if (category != null && category.isNotEmpty && category != 'All') {
      list = list.where((f) => f.category == category).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((f) {
        return f.question.toLowerCase().contains(q) ||
            f.answer.toLowerCase().contains(q) ||
            f.category.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  @override
  Future<GymContactInfo> getContactInfo() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    return _defaultContactInfo;
  }

  @override
  Future<SupportFeedback> submitFeedback({
    required String memberId,
    required String category,
    required String subject,
    required String message,
    String type = 'feedback',
  }) async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }

    final prefix = type == 'issue' ? 'ISS' : 'FDB';
    final id = '$prefix-${DateTime.now().millisecondsSinceEpoch % 100000}';

    final submission = SupportFeedback(
      id: id,
      memberId: memberId,
      category: category,
      subject: subject,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      status: 'Submitted',
    );

    _submissions.add(submission);
    return submission;
  }

  @override
  Future<List<SupportFeedback>> getMemberSubmissions(String memberId) async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    return _submissions.where((s) => s.memberId == memberId).toList();
  }
}
