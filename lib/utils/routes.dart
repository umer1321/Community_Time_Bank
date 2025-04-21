import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../views/screens/auth/login_screen.dart';
import '../views/screens/auth/signup_screen.dart';
import '../views/screens/auth/role_selection_screen.dart';
import '../views/screens/profile/ManageCalendarScreen.dart';
import '../views/screens/profile/profile_screen.dart';
import '../views/screens/profile/edit_profile_screen.dart';
import '../views/screens/profile/manage_profile_screen.dart';
import '../views/screens/profile/ChangePasswordScreen.dart';
import '../views/screens/profile/DeleteAccountScreen.dart';
import '../views/screens/profile/ContactUsScreen.dart';
import '../views/screens/skill/search_skills_screen.dart';
import '../views/screens/skill/skill_detail_screen.dart';
import '../views/screens/skill/RequestSentDetailsScreen.dart';
import '../views/screens/skill/RequestReceivedDetailsScreen.dart';
import '../views/screens/message/message_list_screen.dart';
import '../views/screens/message/chat_screen.dart';
import '../views/screens/review/rate_review_screen.dart';
import '../views/screens/review/review_submitted_screen.dart';
import '../views/screens/review/only_stars_screen.dart';
import '../views/screens/review/all_ratings_screen.dart';
import '../views/screens/review/full_rating_screen.dart';
import '../views/screens/admin/admin_dashboard_screen.dart';
import '../views/screens/admin/manage_users_screen.dart';
import '../views/screens/admin/manage_reviews_screen.dart';
import '../views/screens/home_screen.dart';
import '../views/screens/auth/splash_screen.dart';
import '../views/screens/skill/RequestSkillExchangeScreen.dart';
import '../views/screens/skill/BookSessionScreen.dart';
import '../views/screens/skill/RequestsScreen.dart';
import '../views/screens/skill/confirm_completion_screen.dart';
import '../views/screens/profile/FavoritesScreen.dart';
import '../views/screens/profile/TimeCreditSummaryScreen.dart';
import '../views/screens/profile/ReportIssueScreen.dart';
import '../views/screens/profile/TermsAndConditionsScreen.dart';
import '../views/screens/profile/PrivacyPolicyScreen.dart';

// Route names as constants
class Routes {
  static const String splash = '/splash';
  static const String roleSelection = '/role_selection';
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profile = '/profile';
  static const String editProfile = '/edit_profile';
  static const String manageProfile = '/manage_profile';
  static const String searchSkills = '/search_skills';
  static const String skillDetail = '/skill_detail';
  static const String requestSkill = '/request_skill';
  static const String requestSkillExchange = '/request_skill_exchange';
  static const String bookSession = '/book_session';
  static const String requests = '/requests';
  static const String requestSentDetails = '/request_sent_details';
  static const String requestReceivedDetails = '/request-received-details';
  static const String messageList = '/message_list';
  static const String chat = '/chat';
  static const String rateReview = '/rate_review';
  static const String reviewSubmitted = '/review_submitted';
  static const String onlyStars = '/only_stars';
  static const String allRatings = '/all_ratings';
  static const String fullRating = '/full_rating';
  static const String adminDashboard = '/admin_dashboard';
  static const String manageUsers = '/manage_users';
  static const String manageReviews = '/manage_reviews';
  static const String details = '/details';
  static const String changePassword = '/change_password';
  static const String deleteAccount = '/delete_account';
  static const String manageCalendar = '/manage_calendar';
  static const String contactUs = '/contact_us';
  static const String favorites = '/favorites';
  static const String timeCreditSummary = '/time_credit_summary';
  static const String reportIssue = '/report_issue';
  static const String termsAndConditions = '/terms_and_conditions';
  static const String privacyPolicy = '/privacy_policy';
  static const String confirmCompletion = '/confirm_completion'; // New route for ConfirmCompletionScreen

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case roleSelection:
        final role = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => RoleSelectionScreen(initialRole: role),
        );
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case login:
        final role = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => LoginScreen(initialRole: role),
        );
      case signup:
        final role = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => SignupScreen(initialRole: role),
        );
      case profile:
        final user = settings.arguments as UserModel?;
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      /*case manageProfile:
        return MaterialPageRoute(builder: (_) => const ManageProfileScreen());*/
      case changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
      case deleteAccount:
        return MaterialPageRoute(builder: (_) => const DeleteAccountScreen());
      case manageCalendar:
        return MaterialPageRoute(builder: (_) => const ManageCalendarScreen());
      case contactUs:
        return MaterialPageRoute(builder: (_) => const ContactUsScreen());
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case timeCreditSummary:
        return MaterialPageRoute(builder: (_) => const TimeCreditSummaryScreen());
      case reportIssue:
        return MaterialPageRoute(builder: (_) => const ReportIssueScreen());
      case termsAndConditions:
        return MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen());
      case privacyPolicy:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
      case requestSkillExchange:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('targetUser')) {
          return MaterialPageRoute(
            builder: (_) => RequestSkillExchangeScreen(
              targetUser: args['targetUser'] as UserModel,
              preSelectedSkillOffered: args['preSelectedSkillOffered'] as String?,
              preSelectedSkillWanted: args['preSelectedSkillWanted'] as String?,
            ),
          );
        }
        return _errorRoute('User argument is required for RequestSkillExchangeScreen');
      case bookSession:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null &&
            args.containsKey('targetUser') &&
            args.containsKey('skillOffered') &&
            args.containsKey('skillWanted') &&
            args.containsKey('additionalNote')) {
          return MaterialPageRoute(
            builder: (_) => BookSessionScreen(
              targetUser: args['targetUser'] as UserModel,
              skillOffered: args['skillOffered'] as String,
              skillWanted: args['skillWanted'] as String,
              additionalNote: args['additionalNote'] as String,
            ),
          );
        }
        return _errorRoute('Invalid arguments for BookSessionScreen');
      case requests:
        return MaterialPageRoute(builder: (_) => const RequestsScreen());
      case requestSentDetails:
      case requestSkill:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('requestId')) {
          return MaterialPageRoute(
            builder: (_) => RequestSentDetailsScreen(
              requestId: args['requestId'] as String,
            ),
          );
        }
        return _errorRoute('Request ID is required for RequestSentDetailsScreen');
      case requestReceivedDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('requestId')) {
          return MaterialPageRoute(
            builder: (_) => RequestReceivedDetailsScreen(
              requestId: args['requestId'] as String,
            ),
          );
        }
        return _errorRoute('Request ID is required for RequestReceivedDetailsScreen');
      case searchSkills:
        return MaterialPageRoute(builder: (_) => const SearchSkillsScreen());
      case skillDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('user')) {
          return MaterialPageRoute(
            builder: (_) => SkillDetailScreen(user: args['user'] as UserModel),
          );
        }
        return _errorRoute('User argument is required for SkillDetailScreen');
      case messageList:
        return MaterialPageRoute(builder: (_) => const MessageListScreen());
      case chat:
        return MaterialPageRoute(
          builder: (_) => const ChatScreen(),
          settings: settings, // Pass the arguments through settings
        );
      case rateReview:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null &&
            args.containsKey('requestId') &&
            args.containsKey('reviewedUser') &&
            args.containsKey('reviewerId')) {
          return MaterialPageRoute(
            builder: (_) => RateYourExperienceScreen(
              requestId: args['requestId'] as String,
              reviewedUser: args['reviewedUser'] as UserModel,
              reviewerId: args['reviewerId'] as String,
            ),
          );
        }
        return _errorRoute('Invalid arguments for RateYourExperienceScreen');
      case reviewSubmitted:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('reviewedUser')) {
          return MaterialPageRoute(
            builder: (_) => ReviewSubmittedScreen(
              reviewedUser: args['reviewedUser'] as UserModel,
            ),
          );
        }
        return _errorRoute('Reviewed user is required for ReviewSubmittedScreen');
      case onlyStars:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null &&
            args.containsKey('requestId') &&
            args.containsKey('reviewedUser') &&
            args.containsKey('reviewerId')) {
          return MaterialPageRoute(
            builder: (_) => OnlyStarsScreen(
              requestId: args['requestId'] as String,
              reviewedUser: args['reviewedUser'] as UserModel,
              reviewerId: args['reviewerId'] as String,
            ),
          );
        }
        return _errorRoute('Invalid arguments for OnlyStarsScreen');
      case allRatings:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('userId')) {
          return MaterialPageRoute(
            builder: (_) => AllRatingsScreen(
              userId: args['userId'] as String,
            ),
          );
        }
        return _errorRoute('User ID is required for AllRatingsScreen');
      case fullRating:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('review')) {
          return MaterialPageRoute(
            builder: (_) => FullRatingScreen(
              review: args['review'],
            ),
          );
        }
        return _errorRoute('Review argument is required for FullRatingScreen');
      case confirmCompletion:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null &&
            args.containsKey('requestId') &&
            args.containsKey('targetUserId')) {
          return MaterialPageRoute(
            builder: (_) => ConfirmCompletionScreen(
              requestId: args['requestId'] as String,
              targetUserId: args['targetUserId'] as String,
            ),
          );
        }
        return _errorRoute('Request ID and Target User ID are required for ConfirmCompletionScreen');
     /* case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case manageUsers:
        return MaterialPageRoute(builder: (_) => const ManageUsersScreen());
      case manageReviews:
        return MaterialPageRoute(builder: (_) => const ManageReviewsScreen());*/
      default:
        return _errorRoute('No route defined for ${settings.name}');
    }
  }

  // Helper method for error routes
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text(message)),
      ),
    );
  }
}