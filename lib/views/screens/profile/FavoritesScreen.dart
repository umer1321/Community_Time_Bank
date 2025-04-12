import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/firebase_service.dart';
import '../../../models/user_model.dart';
import '../../../utils/constants.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<UserModel> _favorites = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      // Fetch favorites from Firestore (assuming a subcollection 'favorites' under the user's document)
      final favoritesData = await _firebaseService.getFavorites(user.uid);
      List<UserModel> favorites = [];
      for (var favorite in favoritesData) {
        final favoriteUser = await _firebaseService.getUser(favorite['userId']);
        if (favoriteUser != null) {
          favorites.add(favoriteUser);
        }
      }

      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load favorites: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Favorites',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      )
          : _favorites.isEmpty
          ? const Center(
        child: Text(
          'No favorites added yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final user = _favorites[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundImage: user.profilePictureUrl.isNotEmpty
                  ? NetworkImage(user.profilePictureUrl)
                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint('Error loading profile picture: $exception');
              },
            ),
            title: Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(user.role),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () async {
                // Remove from favorites
                await _firebaseService.removeFavorite(user.uid);
                setState(() {
                  _favorites.removeAt(index);
                });
              },
            ),
          );
        },
      ),
    );
  }
}