import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    setState(() => _isLoading = true);
    final teams = await _apiService.getMyTeams();
    setState(() {
      _teams = teams;
      _isLoading = false;
    });
  }

  // --- TAKIM OLUŞTURMA DİYALOĞU ---
  void _showCreateTeamDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yeni Takım Oluştur"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Takım Adı (Örn: Pazarlama)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await _apiService.createTeam(nameController.text.trim());
                if (success) {
                  _fetchTeams(); // Listeyi yenile
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Takım oluşturuldu!")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata oluştu.")));
                }
              }
            },
            child: const Text("Oluştur", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- ÜYE EKLEME DİYALOĞU ---
  void _showAddMemberDialog(int teamId, String teamName) {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("$teamName'a Üye Ekle"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(hintText: "Arkadaşının Email Adresi"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                Navigator.pop(ctx);
                final msg = await _apiService.addMemberToTeam(teamId, emailController.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? "İşlem tamam")));
                _fetchTeams(); // Üye sayısı değiştiği için yenile
              }
            },
            child: const Text("Davet Et", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Takımlarım"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTeamDialog,
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Takım Kur", style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_off_rounded, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("Henüz bir takımın yok.", style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _teams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final team = _teams[index];
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.groups_rounded, color: Color(0xFF6C63FF)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${team['member_count']} Üye",
                                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showAddMemberDialog(team['id'], team['name']),
                            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.indigo),
                            tooltip: "Üye Ekle",
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}