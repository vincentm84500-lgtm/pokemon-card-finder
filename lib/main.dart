import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokémon Card Finder',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: HomeScreen(),
    );
  }
}

class PokemonCard {
  final String id;
  final String name;
  final String imageUrl;
  final String setNombre;
  final String rarity;
  final String language;
  final double? marketPrice;

  PokemonCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.setNombre,
    required this.rarity,
    required this.language,
    this.marketPrice,
  });

  factory PokemonCard.fromJson(Map<String, dynamic> json, String lang) {
    return PokemonCard(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Inconnu',
      imageUrl: json['images'] != null ? json['images']['large'] ?? '' : '',
      setNombre: json['set'] != null ? json['set']['name'] ?? '' : '',
      rarity: json['rarity'] ?? 'Commune',
      language: lang,
      marketPrice: json['cardmarket'] != null 
          ? (json['cardmarket']['prices']['averageSellPrice'] as num?)?.toDouble() 
          : null,
    );
  }
}

class TcgApiService {
  static const String apiKey = ''; 
  static const String baseUrl = 'https://api.pokemontcg.io/v2/cards';

  Future<List<PokemonCard>> searchCards(String query, String language) async {
    final url = Uri.parse('$baseUrl?q=name:$query*');
    try {
      final response = await http.get(url, headers: {'X-Api-Key': apiKey});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List dataCards = data['data'];
        return dataCards.map((jsonCard) => PokemonCard.fromJson(jsonCard, language)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TcgApiService _apiService = TcgApiService();
  
  String _selectedLanguage = 'FR';
  List<PokemonCard> _results = [];
  bool _isLoading = false;

  void _performSearch() async {
    if (_searchController.text.isEmpty) return;
    setState(() { _isLoading = true; });
    final cards = await _apiService.searchCards(_searchController.text, _selectedLanguage);
    setState(() {
      _results = cards;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recherche Cartes Pokémon (FR/JP)'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text('Français (FR)'),
                  selected: _selectedLanguage == 'FR',
                  onSelected: (selected) { setState(() { _selectedLanguage = 'FR'; }); },
                ),
                SizedBox(width: 12),
                ChoiceChip(
                  label: Text('Japonais (JP)'),
                  selected: _selectedLanguage == 'JP',
                  onSelected: (selected) { setState(() { _selectedLanguage = 'JP'; }); },
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Nom du Pokémon (ex: Charizard)',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _performSearch,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final card = _results[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: card.imageUrl.isNotEmpty
                                ? Image.network(card.imageUrl, width: 50, fit: BoxFit.cover)
                                : Icon(Icons.image_not_supported),
                            title: Text(card.name, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${card.setNombre} - Rareté : ${card.rarity}'),
                            trailing: Text(
                              card.marketPrice != null ? '${card.marketPrice} €' : 'N/C',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
