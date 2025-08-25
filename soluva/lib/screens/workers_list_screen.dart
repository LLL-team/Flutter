import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/worker_service.dart';

class WorkersListScreen extends StatefulWidget {
  final String category;
  const WorkersListScreen({super.key, required this.category});

  @override
  State<WorkersListScreen> createState() => _WorkersListScreenState();
}

class _WorkersListScreenState extends State<WorkersListScreen> {
  bool _loading = true;
  List<dynamic> _workers = [];

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
 print('Fetching workers for category: ${widget.category}');
  }

  Future<void> _fetchWorkers() async {
   
    setState(() => _loading = true);
    try {
      final workers = await WorkerService.getWorkersByCategory(widget.category);
      print(workers);
      setState(() {
        _workers = workers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trabajadores de ${widget.category}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _workers.isEmpty
              ? const Center(child: Text('No hay trabajadores en esta categoría.'))
              : ListView.builder(
                  itemCount: _workers.length,
                  itemBuilder: (context, index) {
                    final worker = _workers[index];
                    return Card(
                      child: ListTile(
                        leading: worker['profile_photo'] != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  '${worker['profile_photo'].toString().startsWith('http') ? '' : 'http://127.0.0.1:8000'}${worker['profile_photo']}',
                                ),
                              )
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text('${worker['name']} ${worker['last_name']}'),
                        subtitle: Text(worker['description'] ?? ''),
                      ),
                    );
                  },
                ),
    );
  }
}

