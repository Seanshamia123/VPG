import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'terms_and_conditions_screen.dart';
// User model to manage profile data
class UserProfile {
  String name;
  String username;
  String profileImageUrl;
  String location;

  UserProfile({
    required this.name,
    required this.username,
    required this.profileImageUrl,
    required this.location,
  });
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escort',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isDrawerOpen = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  // User profile data
  UserProfile userProfile = UserProfile(
    name: 'Roster_123',
    username: '@roster123',
    profileImageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
    location: 'New York, NY',
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
    
    if (_isDrawerOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _navigateToEditProfile() async {
    final updatedProfile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userProfile: userProfile),
      ),
    );
    
    if (updatedProfile != null) {
      setState(() {
        userProfile = updatedProfile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMainContent(),
          
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          
          if (_isDrawerOpen)
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_slideAnimation.value * 300, 0),
                  child: _buildSidePanel(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Escort',
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _toggleDrawer,
              borderRadius: BorderRadius.circular(16),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(userProfile.profileImageUrl),
                backgroundColor: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(userProfile.profileImageUrl),
                  backgroundColor: Colors.grey[700],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "What's on your mind ?",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            height: 100,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Top Advertisers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildStoryItem('Stacy', 'https://images.unsplash.com/photo-1481214110143-ed630356e1bb?q=80&w=387&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
                      _buildStoryItem('Smith', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face'),
                      _buildStoryItem('Kriston', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&h=100&fit=crop&crop=face'),
                      _buildStoryItem('Emma', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1481214110143-ed630356e1bb?q=80&w=387&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
                                backgroundColor: Colors.grey[700],
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kriston Watson',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.grey[400],
                                        size: 14,
                                      ),
                                      Text(
                                        'New York, NY',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Spacer(),
                              Icon(
                                Icons.more_vert,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                        
                        Container(
                          height: 300,
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1481214110143-ed630356e1bb?q=80&w=387&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Hey',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.favorite_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face'),
                          backgroundColor: Colors.grey[700],
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Smith Johnson',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '14',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.grey[600],
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        width: 300,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _toggleDrawer,
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(userProfile.profileImageUrl),
                    backgroundColor: Colors.grey[700],
                  ),
                  SizedBox(height: 12),
                  Text(
                    userProfile.name,
                    style: TextStyle(
                      
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    userProfile.username,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Column(
                children: [
                  _buildMenuItem(Icons.edit, 'Edit Profile', _navigateToEditProfile),
                  _buildMenuItem(Icons.flash_on, 'Boost', null),
                  _buildMenuItem(Icons.help_outline, 'What is', null),
                 _buildMenuItem(Icons.settings, 'Settings', () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SettingsScreen(),
    ),
  );
}),
                 _buildMenuItem(Icons.info_outline, 'Terms of conditions', () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TermsAndConditionsScreen(),
    ),
  );
}),
                  Spacer(),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Log Out',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[400],
              size: 20,
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStoryItem(String name, String imageUrl) {
    return Container(
      margin: EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.yellow, Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              margin: EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Edit Profile Screen
class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _locationController;
  late String _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.name);
    _usernameController = TextEditingController(text: widget.userProfile.username);
    _locationController = TextEditingController(text: widget.userProfile.location);
    _profileImageUrl = widget.userProfile.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final updatedProfile = UserProfile(
      name: _nameController.text,
      username: _usernameController.text,
      profileImageUrl: _profileImageUrl,
      location: _locationController.text,
    );
    
    Navigator.pop(context, updatedProfile);
  }

  void _changeProfileImage() {
    // List of sample profile images
    final List<String> sampleImages = [
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&h=150&fit=crop&crop=face',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
      'https://images.unsplash.com/photo-1494790108755-2616b612b789?w=150&h=150&fit=crop&crop=face',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Profile Picture',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: sampleImages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _profileImageUrl = sampleImages[index];
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _profileImageUrl == sampleImages[index] 
                              ? Colors.yellow 
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(sampleImages[index]),
                        backgroundColor: Colors.grey[700],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 20),
            // Profile picture section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(_profileImageUrl),
                    backgroundColor: Colors.grey[700],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _changeProfileImage,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            // Form fields
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              icon: Icons.person,
            ),
            
            SizedBox(height: 20),
            
            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.alternate_email,
            ),
            
            SizedBox(height: 20),
            
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              icon: Icons.location_on,
            ),
            
            SizedBox(height: 40),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.yellow, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}