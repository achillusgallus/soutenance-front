import 'package:flutter/material.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminParameter extends StatefulWidget {
  const AdminParameter({super.key});

  @override
  State<AdminParameter> createState() => _AdminParameterState();
}

class _AdminParameterState extends State<AdminParameter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: 'Paramètres',
              onBack: () {
                Navigator.pop(context);
              },
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(
                  top: 20,
                  left: 16,
                  right: 16,
                  bottom: 0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Profile Section
                    Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey,
                          child: Icon(
                            FontAwesomeIcons.userLarge,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Administrateur',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'admin@togoschool.tg',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement edit profile
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Modifier le profil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              50,
                              6,
                              132,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Divider(),

                    // Settings Options
                    _buildSettingsTile(
                      icon: FontAwesomeIcons.bell,
                      title: 'Notifications',
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      icon: FontAwesomeIcons.shieldHalved,
                      title: 'Sécurité',
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      icon: FontAwesomeIcons.circleInfo,
                      title: 'À propos',
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      icon: FontAwesomeIcons.rightFromBracket,
                      title: 'Se déconnecter',
                      onTap: () {
                        // TODO: Implement Logout
                        Navigator.pop(context);
                      },
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: color.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }
}
