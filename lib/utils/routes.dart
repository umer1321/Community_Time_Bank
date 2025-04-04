// lib/utils/routes.dart
import 'package:flutter/material.dart';
import '../views/screens/auth/login_screen.dart';
import '../views/screens/auth/signup_screen.dart';
import '../views/screens/auth/role_selection_screen.dart'; // New import
import '../views/screens/profile/profile_screen.dart';
import '../views/screens/profile/edit_profile_screen.dart';
import '../views/screens/profile/manage_profile_screen.dart';
import '../views/screens/skill/search_skills_screen.dart';
import '../views/screens/skill/skill_detail_screen.dart';
import '../views/screens/skill/request_skill_screen.dart';
import '../views/screens/message/message_list_screen.dart';
import '../views/screens/message/chat_screen.dart';
import '../views/screens/review/rate_review_screen.dart';
import '../views/screens/admin/admin_dashboard_screen.dart';
import '../views/screens/admin/manage_users_screen.dart';
import '../views/screens/admin/manage_reviews_screen.dart';
import '../views/screens/home_screen.dart';
import '../views/screens/auth/splash_screen.dart'; // New import

// Route names as constants
class Routes {
  static const String splash = '/splash'; // New route
  static const String roleSelection = '/role_selection'; // New route
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profile = '/profile';
  static const String editProfile = '/edit_profile';
  static const String manageProfile = '/manage_profile';
  static const String searchSkills = '/search_skills';
  static const String skillDetail = '/skill_detail';
  static const String requestSkill = '/request_skill';
  static const String messageList = '/message_list';
  static const String chat = '/chat';
  static const String rateReview = '/rate_review';
  static const String adminDashboard = '/admin_dashboard';
  static const String manageUsers = '/manage_users';
  static const String manageReviews = '/manage_reviews';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
   /*  case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());*/
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
     /* case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case manageProfile:
        return MaterialPageRoute(builder: (_) => const ManageProfileScreen());
      case searchSkills:
        return MaterialPageRoute(builder: (_) => const SearchSkillsScreen());
      case skillDetail:
        return MaterialPageRoute(builder: (_) => const SkillDetailScreen());
      case requestSkill:
        return MaterialPageRoute(builder: (_) => const RequestSkillScreen());
      case messageList:
        return MaterialPageRoute(builder: (_) => const MessageListScreen());
      case chat:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      case rateReview:
        return MaterialPageRoute(builder: (_) => const RateReviewScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case manageUsers:
        return MaterialPageRoute(builder: (_) => const ManageUsersScreen());
      case manageReviews:
        return MaterialPageRoute(builder: (_) => const ManageReviewsScreen());*/
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}