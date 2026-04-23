import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TrialExpiredScreen extends StatefulWidget {
  const TrialExpiredScreen({super.key});

  @override
  State<TrialExpiredScreen> createState() => _TrialExpiredScreenState();
}

class _TrialExpiredScreenState extends State<TrialExpiredScreen> {
  bool _showContactInfo = false;

  void _launchPhone() async {
    final Uri telLaunchUri = Uri(
      scheme: 'tel',
      path: '0771311965',
    );
    if (await canLaunchUrl(telLaunchUri)) {
      await launchUrl(telLaunchUri);
    }
  }

  void _launchWhatsApp() async {
    final Uri whatsappLaunchUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '213771311965',
    );
    if (await canLaunchUrl(whatsappLaunchUri)) {
      await launchUrl(whatsappLaunchUri);
    }
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'samydz888@gmail.com',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                "Période d'essai expirée",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Votre période d'essai gratuit de 30 jours est terminée.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Veuillez contacter notre équipe pour obtenir une licence complète.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showContactInfo = !_showContactInfo;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  _showContactInfo ? "Masquer les contacts" : "Contactez-nous",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              if (_showContactInfo)
                Column(
                  children: [
                    // Phone contact
                    ListTile(
                      leading: const Icon(Icons.phone, color: Colors.blue),
                      title: const Text("0771311965"),
                      onTap: _launchPhone,
                    ),
                    // WhatsApp contact
                    ListTile(
                      leading: Image.asset(
                        'assets/images/whatsapp.png',
                        width: 24,
                        height: 24,
                      ),
                      title: const Text("0771311965 (WhatsApp)"),
                      onTap: _launchWhatsApp,
                    ),
                    // Email contact
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.red),
                      title: const Text("samydz888@gmail.com"),
                      onTap: _launchEmail,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}