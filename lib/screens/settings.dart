import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/utilisateurs.dart';
import '/db/usersdao.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const _kBg       = Color(0xFFF4F6FB);
const _kCard     = Colors.white;
const _kAccent   = Color(0xFF4A6CF7);
const _kAdminClr = Color(0xFFE53E3E);
const _kStdClr   = Color(0xFF4A6CF7);
const _kBorder   = Color(0xFFE4E7F0);
const _kLabel    = Color(0xFF8A94A6);
const _kTitle    = Color(0xFF1A1D27);

class ParametersScreen extends StatefulWidget {
  const ParametersScreen({super.key});

  @override
  State<ParametersScreen> createState() => _ParametersScreenState();
}

class _ParametersScreenState extends State<ParametersScreen> {
  final UserDao _userDao = UserDao();
  List<AppUser> _adminUsers    = [];
  List<AppUser> _standardUsers = [];
  bool _isLoading = true;

  String _selectedLanguage = 'Français';
  String _selectedTimezone = 'UTC+01:00 (Algérie)';

  static const _languages = ['Français', 'English', 'العربية'];
  static const _timezones = [
    'UTC+01:00 (Algérie)',
    'UTC+00:00 (GMT)',
    'UTC+01:00 (Paris)',
    'UTC+02:00 (Europe de l\'Est)',
    'UTC+03:00 (Moscou)',
    'UTC-05:00 (Eastern Time)',
    'UTC-06:00 (Central Time)',
    'UTC-08:00 (Pacific Time)',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'Français';
      _selectedTimezone = prefs.getString('timezone') ?? 'UTC+01:00 (Algérie)';
    });
  }

  Future<void> _saveSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _loadUsers() async {
    try {
      final allUsers = await _userDao.getAllUsers();
      setState(() {
        _adminUsers    = allUsers.where((u) => u.isAdmin).toList();
        _standardUsers = allUsers.where((u) => u.isStandard).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement utilisateurs: $e');
      setState(() => _isLoading = false);
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showAddUserDialog({UserRole role = UserRole.standard, AppUser? existingUser}) {
    final usernameCtrl        = TextEditingController(text: existingUser?.username ?? '');
    final passwordCtrl        = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    UserRole selectedRole     = existingUser?.role ?? role;
    bool showPassword         = false;
    bool showConfirm          = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_add_alt_1, color: _kAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                existingUser == null ? 'Ajouter un utilisateur' : 'Modifier l\'utilisateur',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: _kTitle),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  _dlgField(
                    controller: usernameCtrl,
                    label: 'Nom d\'utilisateur',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _dlgField(
                    controller: passwordCtrl,
                    label: existingUser == null
                        ? 'Mot de passe'
                        : 'Nouveau mot de passe (vide = inchangé)',
                    icon: Icons.lock_outline,
                    obscure: !showPassword,
                    suffix: IconButton(
                      icon: Icon(
                          showPassword ? Icons.visibility : Icons.visibility_off,
                          color: _kLabel, size: 20),
                      onPressed: () => setDlg(() => showPassword = !showPassword),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _dlgField(
                    controller: confirmPasswordCtrl,
                    label: 'Confirmer le mot de passe',
                    icon: Icons.lock_outline,
                    obscure: !showConfirm,
                    suffix: IconButton(
                      icon: Icon(
                          showConfirm ? Icons.visibility : Icons.visibility_off,
                          color: _kLabel, size: 20),
                      onPressed: () => setDlg(() => showConfirm = !showConfirm),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Rôle',
                      prefixIcon: const Icon(
                          Icons.admin_panel_settings_outlined, color: _kLabel, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                    ),
                    items: UserRole.values.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r == UserRole.admin ? 'Administrateur' : 'Standard'),
                    )).toList(),
                    onChanged: (r) { if (r != null) setDlg(() => selectedRole = r); },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: _kLabel)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                if (usernameCtrl.text.isEmpty) {
                  _snack(ctx, 'Le nom d\'utilisateur est requis');
                  return;
                }
                if (existingUser == null && passwordCtrl.text.isEmpty) {
                  _snack(ctx, 'Le mot de passe est requis');
                  return;
                }
                if (passwordCtrl.text != confirmPasswordCtrl.text) {
                  _snack(ctx, 'Les mots de passe ne correspondent pas');
                  return;
                }
                try {
                  final newUser = AppUser(
                    id: existingUser?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    username: usernameCtrl.text.trim(),
                    password: passwordCtrl.text.isNotEmpty
                        ? passwordCtrl.text
                        : existingUser?.password ?? '',
                    role: selectedRole,
                  );
                  if (existingUser == null) {
                    await _userDao.insertUser(newUser);
                    _snack(ctx, 'Utilisateur ajouté avec succès');
                  } else {
                    await _userDao.updateUser(newUser);
                    _snack(ctx, 'Utilisateur modifié avec succès');
                  }
                  Navigator.pop(ctx);
                  _loadUsers();
                } catch (e) {
                  _snack(ctx, 'Erreur : ${e.toString()}');
                }
              },
              child: Text(
                existingUser == null ? 'Ajouter' : 'Enregistrer',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _kAdminClr, size: 26),
            SizedBox(width: 10),
            Text('Confirmer la suppression',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: _kTitle)),
          ],
        ),
        content: Text(
          'Supprimer l\'utilisateur "${user.username}" ?',
          style: const TextStyle(color: _kLabel, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: _kLabel)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAdminClr,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                await _userDao.deleteUser(user.id);
                _snack(ctx, 'Utilisateur supprimé');
                Navigator.pop(ctx);
                _loadUsers();
              } catch (e) {
                _snack(ctx, 'Erreur : ${e.toString()}');
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Reusable Widgets ──────────────────────────────────────────────────────

  Widget _dlgField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kLabel, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _dropDeco() => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF8F9FC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kAccent, width: 1.5),
    ),
  );

  Widget _sectionIcon(IconData icon, Color color) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _miniIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  // ── Section: Language & Region ────────────────────────────────────────────

  Widget _buildLanguageRegionSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionIcon(Icons.language, _kAccent),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Language & Region',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kTitle)),
                  SizedBox(height: 2),
                  Text('Set your preferred language and time zone',
                      style: TextStyle(fontSize: 12, color: _kLabel)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 20),
          const Text('Language',
              style: TextStyle(
                  fontSize: 13, color: _kLabel, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: _dropDeco(),
            items: _languages
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() => _selectedLanguage = val);
              _saveSetting('language', val);
            },
          ),
          const SizedBox(height: 18),
          const Text('Time Zone',
              style: TextStyle(
                  fontSize: 13, color: _kLabel, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedTimezone,
            decoration: _dropDeco(),
            items: _timezones
                .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() => _selectedTimezone = val);
              _saveSetting('timezone', val);
            },
          ),
        ],
      ),
    );
  }

  // ── Section: Users ────────────────────────────────────────────────────────

  Widget _buildUserSection(String title, List<AppUser> users, UserRole role) {
    final isAdmin = role == UserRole.admin;
    final accent  = isAdmin ? _kAdminClr : _kStdClr;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _sectionIcon(
                    isAdmin ? Icons.admin_panel_settings : Icons.group,
                    accent,
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kTitle)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(role: role),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Ajouter',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (users.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.person_off_outlined,
                      size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('Aucun utilisateur',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.88,
              ),
              itemCount: users.length,
              itemBuilder: (_, i) => _buildUserCard(users[i], accent),
            ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppUser user, Color accent) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.25), width: 1.5),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: accent.withOpacity(0.15),
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: accent),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    user.username,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: _kTitle),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.isAdmin ? 'Admin' : 'Standard',
                      style: TextStyle(
                          fontSize: 9,
                          color: accent,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4, right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _miniIcon(Icons.edit, _kAccent,
                    () => _showAddUserDialog(existingUser: user)),
                _miniIcon(Icons.delete, _kAdminClr,
                    () => _showDeleteConfirmation(user)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionIcon(Icons.storage, _kAccent),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data Management',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kTitle)),
                  SizedBox(height: 2),
                  Text('Export, import or backup your data',
                      style: TextStyle(fontSize: 12, color: _kLabel)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _dataButton(Icons.upload_file, 'Export All Data', _kAccent)),
              const SizedBox(width: 12),
              Expanded(child: _dataButton(Icons.download, 'Import Data', _kAccent)),
              const SizedBox(width: 12),
              Expanded(child: _dataButton(Icons.backup, 'Backup Database', _kAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dataButton(IconData icon, String label, Color color) {
    return OutlinedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label — bientôt disponible')),
        );
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: _kBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFFF8F9FC),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTitle)),
        ],
      ),
    );
  }

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        toolbarHeight: 74,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Settings',
                style: TextStyle(
                    color: _kTitle,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            SizedBox(height: 2),
            Text('Manage your application preferences',
                style: TextStyle(
                    color: _kLabel,
                    fontSize: 13,
                    fontWeight: FontWeight.normal)),
          ],
        ),
        iconTheme: const IconThemeData(color: _kTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
              label: const Text('Actualiser',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLanguageRegionSection(),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildUserSection(
                        'Administrateurs', _adminUsers, UserRole.admin),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildUserSection(
                        'Utilisateurs Standard', _standardUsers, UserRole.standard),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDataManagementSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
