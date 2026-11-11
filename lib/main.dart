import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Attivita {
  String titolo;
  String descrizione;
  bool completata;
  bool importante;
  final DateTime dataCreazione;
  DateTime? dataCompletamento;

  Attivita({
    required this.titolo,
    this.descrizione = '',
    this.completata = false,
    this.importante = false,
    DateTime? dataCreazione,
    this.dataCompletamento,
  }) : dataCreazione = dataCreazione ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'titolo': titolo,
    'descrizione': descrizione,
    'completata': completata,
    'importante': importante,
    'dataCreazione': dataCreazione.toIso8601String(),
    'dataCompletamento': dataCompletamento?.toIso8601String(),
  };

  factory Attivita.fromJson(Map<String, dynamic> json) => Attivita(
    titolo: json['titolo'],
    descrizione: json['descrizione'] ?? '',
    completata: json['completata'] ?? false,
    importante: json['importante'] ?? false,
    dataCreazione: DateTime.parse(json['dataCreazione']),
    dataCompletamento: json['dataCompletamento'] != null
        ? DateTime.parse(json['dataCompletamento'])
        : null,
  );
}

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List Francesco Pirozzi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF2800),
          primary: const Color(0xFFFF2800),
        ),
        useMaterial3: true,
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Attivita> _attivita = [];

  final TextEditingController _titoloController = TextEditingController();
  final TextEditingController _descrizioneController = TextEditingController();
  bool _nuovaImportante = false;
  String? _erroreTitolo;

  int get _attivitaCompletate => _attivita.where((a) => a.completata).length;

  //Logica di salvataggio
  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  Future<void> _salvaDati() async {
    final prefs = await SharedPreferences.getInstance();
    final String datiJson = jsonEncode(_attivita.map((a) => a.toJson()).toList());
    await prefs.setString('memoria_attivita', datiJson);
  }

  Future<void> _caricaDati() async {
    final prefs = await SharedPreferences.getInstance();
    final String? datiJson = prefs.getString('memoria_attivita');
    if (datiJson != null) {
      final List<dynamic> decodificati = jsonDecode(datiJson);
      setState(() {
        _attivita = decodificati.map((item) => Attivita.fromJson(item)).toList();
      });
    }
  }

  String _formattaData(DateTime dt) {
    final g = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final a = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$g/$m/$a alle $h:$min";
  }

  //S1 (R1) - Aggiungere un'attività
  void _mostraDialogoAggiunta() {
    _titoloController.clear();
    _descrizioneController.clear();
    _nuovaImportante = false;
    _erroreTitolo = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('Nuova Attività'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _titoloController,
                        decoration: InputDecoration(
                          labelText: 'Titolo (obbligatorio)',
                          errorText: _erroreTitolo,
                        ),
                        onChanged: (text) {
                          if (_erroreTitolo != null) {
                            setStateDialog(() => _erroreTitolo = null);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descrizioneController,
                        decoration: const InputDecoration(
                          labelText: 'Descrizione (opzionale)',
                        ),
                        maxLines: 2,
                      ),
                      CheckboxListTile(
                        title: const Text('Importante'),
                        value: _nuovaImportante,
                        onChanged: (val) => setStateDialog(() => _nuovaImportante = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      )
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_titoloController.text.trim().isEmpty) {
                        setStateDialog(() => _erroreTitolo = 'Il titolo è obbligatorio');
                        return;
                      }

                      setState(() {
                        _attivita.add(Attivita(
                          titolo: _titoloController.text.trim(),
                          descrizione: _descrizioneController.text.trim(),
                          importante: _nuovaImportante,
                        ));
                        _salvaDati();
                      });

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attività aggiunta con successo!')),
                      );
                    },
                    child: const Text('Conferma'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  //S3 (R3) - Aggiorna lo stato di un'attività
  void _mostraDettagliAttivita(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              final attivita = _attivita[index];
              return AlertDialog(
                title: Text(
                    attivita.titolo,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF2800))
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (attivita.descrizione.isNotEmpty) ...[
                        const Text('Descrizione:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF2800))),
                        const SizedBox(height: 4),
                        Text(attivita.descrizione),
                        const SizedBox(height: 16),
                      ],
                      if (attivita.importante) ...[
                        const Text('Importante', style: TextStyle(color: Color(0xFFFF2800), fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                      ],
                      Text(
                          'Aggiunta il: ${_formattaData(attivita.dataCreazione)}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic)
                      ),
                      if (attivita.completata && attivita.dataCompletamento != null) ...[
                        const SizedBox(height: 4),
                        Text(
                            'Completata il: ${_formattaData(attivita.dataCompletamento!)}',
                            style: const TextStyle(fontSize: 13, color: Colors.green, fontStyle: FontStyle.italic)
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),

                      CheckboxListTile(
                        title: Text(attivita.completata ? 'Attività completata' : 'Da completare',
                            style: TextStyle(fontWeight: attivita.completata ? FontWeight.bold : FontWeight.normal)
                        ),
                        value: attivita.completata,
                        onChanged: (val) {
                          setStateDialog(() {
                            attivita.completata = val ?? false;
                            if (attivita.completata) {
                              attivita.dataCompletamento = DateTime.now();
                            } else {
                              attivita.dataCompletamento = null;
                            }
                          });
                          setState(() {
                            _salvaDati();
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Chiudi'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  //S4 (R4) - Eliminare un'attività
  void _confermaEliminazione(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elimina attività'),
          content: const Text('Sei sicuro di voler eliminare questa attività?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _attivita.removeAt(index);
                  _salvaDati();
                });
                Navigator.pop(context);
              },
              child: const Text('Elimina', style: TextStyle(color: Color(0xFFFF2800))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-do list Francesco Pirozzi', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF2800),
      ),

      //S2 (R2) - Consultare le attività
      body: _attivita.isEmpty
          ? const Center(
        child: Text(
          'Nessuna attività.\nPremi il tasto + per aggiungerne una.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: _attivita.length,
        itemBuilder: (context, index) {
          final attivita = _attivita[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              onTap: () => _mostraDettagliAttivita(index),
              title: Text(
                attivita.titolo,
                style: TextStyle(
                  decoration: attivita.completata ? TextDecoration.lineThrough : null,
                  fontWeight: attivita.importante ? FontWeight.bold : FontWeight.normal,
                  color: attivita.importante && !attivita.completata ? const Color(0xFFFF2800) : null,
                ),
              ),
              subtitle: Text(attivita.completata ? "Completata" : "Tocca per i dettagli"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Color(0xFFFF2800)),
                onPressed: () => _confermaEliminazione(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostraDialogoAggiunta,
        tooltip: 'Aggiungi attività',
        backgroundColor: const Color(0xFFFF2800),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Completate: $_attivitaCompletate su ${_attivita.length}',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF2800)
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}