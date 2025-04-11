
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../views/screens/auth/login_screen.dart';
import '../views/screens/auth/signup_screen.dart';
import '../views/screens/auth/role_selection_screen.dart';
import '../views/screens/profile/profile_screen.dart';
import '../views/screens/profile/edit_profile_screen.dart';
import '../views/screens/profile/manage_profile_screen.dart';
import '../views/screens/skill/search_skills_screen.dart';
import '../views/screens/skill/skill_detail_screen.dart';
import '../views/screens/skill/RequestSentDetailsScreen.dart';
import '../views/screens/skill/RequestReceivedDetailsScreen.dart'; // Added import
import '../views/screens/message/message_list_screen.dart';
import '../views/screens/message/chat_screen.dart';
import '../views/screens/review/rate_review_screen.dart';
import '../views/screens/admin/admin_dashboard_screen.dart';
import '../views/screens/admin/manage_users_screen.dart';
import '../views/screens/admin/manage_reviews_screen.dart';
import '../views/screens/home_screen.dart';
import '../views/screens/auth/splash_screen.dart';
import '../views/screens/skill/RequestSkillExchangeScreen.dart';
import '../views/screens/skill/BookSessionScreen.dart';
import '../views/screens/skill/RequestsScreen.dart';
import '../views/screens/skill/ConfirmCompletionScreen.dart'; // New import
import '../views/screens/review/rate_review_screen.dart'; // New import


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
  static const String requestReceivedDetails = '/request-received-details'; // Added route
  static const String messageList = '/message_list';
  static const String chat = '/chat';
  static const String rateReview = '/rate_review';
  static const String adminDashboard = '/admin_dashboard';
  static const String manageUsers = '/manage_users';
  static const String manageReviews = '/manage_reviews';
  static const String details = '/details';
  static const String confirmCompletion = '/confirmCompletion'; // New route
  static const String review = '/review'; // New route

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
        if (user != null) {
          return MaterialPageRoute(builder: (_) => ProfileScreen(user: user));
        }
        return _errorRoute('User argument is required for ProfileScreen');
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
      case requestSkill: // Handle both routes for RequestSentDetailsScreen
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
     /* case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case manageProfile:
        return MaterialPageRoute(builder: (_) => const ManageProfileScreen());*/
      case messageList:
        return MaterialPageRoute(builder: (_) => const MessageListScreen());
      case chat:
      // Pass the arguments directly to ChatScreen via settings
        return MaterialPageRoute(
          builder: (_) => const ChatScreen(),
          settings: settings, // Pass the arguments through settings
        );
      /*case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('chatId') && args.containsKey('otherUser')) {
          return MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: args['chatId'] as String,
              otherUser: args['otherUser'] as UserModel,
            ),
          );
        }
        return _errorRoute('Chat ID and other user are required for ChatScreen');*/
      case confirmCompletion:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('requestId') && args.containsKey('targetUserId')) {
          return MaterialPageRoute(builder: (_) => ConfirmCompletionScreen());
        }
        return _errorRoute('Request ID and target user ID are required for ConfirmCompletionScreen');
      case review:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('requestId') && args.containsKey('targetUserId')) {
          return MaterialPageRoute(builder: (_) => const ReviewScreen());
        }
        return _errorRoute('Request ID and target user ID are required for ReviewScreen');
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