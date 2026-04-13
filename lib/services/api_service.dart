import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../utils/settings_service.dart';
import '../utils/secure_store.dart';

class ApiService {
  final SettingsService _settings = SettingsService();
  final SecureStore _secureStore = SecureStore();

  Future<String> _baseUrl() async {
    final url = await _settings.getApiBaseUrl();
    if (url.isEmpty) {
      throw Exception('API base URL non configurée');
    }
    return url;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _secureStore.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token API manquant');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<String> uploadReceipt(File file) async {
    final url = await _baseUrl();
    final token = await _secureStore.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token API manquant');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$url/api/receipts'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['url'] as String;
    }
    throw Exception('Erreur upload (${response.statusCode})');
  }

  Future<List<Transaction>> getTransactions() async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.get(Uri.parse('$url/api/transactions'), headers: headers);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => Transaction.fromMap(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Erreur API (${res.statusCode})');
  }

  Future<Transaction> createTransaction(Transaction t) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$url/api/transactions'),
      headers: headers,
      body: jsonEncode(t.toMap()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Transaction.fromMap(data);
    }
    throw Exception('Erreur API (${res.statusCode})');
  }

  Future<void> updateTransaction(Transaction t) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.put(
      Uri.parse('$url/api/transactions/${t.id}'),
      headers: headers,
      body: jsonEncode(t.toMap()),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur API (${res.statusCode})');
    }
  }

  Future<void> deleteTransaction(String id) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.delete(
      Uri.parse('$url/api/transactions/$id'),
      headers: headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur API (${res.statusCode})');
    }
  }

  Future<List<Categorie>> getCategories() async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.get(Uri.parse('$url/api/categories'), headers: headers);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => Categorie.fromMap(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Erreur API (${res.statusCode})');
  }

  Future<Categorie> createCategory(Categorie c) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$url/api/categories'),
      headers: headers,
      body: jsonEncode(c.toMap()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Categorie.fromMap(data);
    }
    throw Exception('Erreur API (${res.statusCode})');
  }

  Future<void> updateCategory(Categorie c) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.put(
      Uri.parse('$url/api/categories/${c.id}'),
      headers: headers,
      body: jsonEncode(c.toMap()),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur API (${res.statusCode})');
    }
  }

  Future<void> deleteCategory(String id) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.delete(
      Uri.parse('$url/api/categories/$id'),
      headers: headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur API (${res.statusCode})');
    }
  }

  Future<List<Budget>> getBudgets() async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.get(Uri.parse('$url/api/budgets'), headers: headers);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => Budget.fromMap(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Erreur API (${res.statusCode})');
  }

  Future<Budget> createBudget(Budget b) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$url/api/budgets'),
      headers: headers,
      body: jsonEncode(b.toMap()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Budget.fromMap(data);
    }
    throw Exception('Erreur API (${res.statusCode})');
  }

  Future<void> updateBudget(Budget b) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.put(
      Uri.parse('$url/api/budgets/${b.id}'),
      headers: headers,
      body: jsonEncode(b.toMap()),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur API (${res.statusCode})');
    }
  }

  Future<void> deleteBudget(String id) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.delete(
      Uri.parse('$url/api/budgets/$id'),
      headers: headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur API (${res.statusCode})');
    }
  }

  Future<List<Objectif>> getObjectifs() async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.get(Uri.parse('$url/api/objectifs'), headers: headers);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => Objectif.fromMap(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Erreur API (${res.statusCode})');
  }

  Future<Objectif> createObjectif(Objectif o) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$url/api/objectifs'),
      headers: headers,
      body: jsonEncode(o.toMap()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Objectif.fromMap(data);
    }
    throw Exception('Erreur API (${res.statusCode})');
  }

  Future<void> updateObjectif(Objectif o) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.put(
      Uri.parse('$url/api/objectifs/${o.id}'),
      headers: headers,
      body: jsonEncode(o.toMap()),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur API (${res.statusCode})');
    }
  }

  Future<void> deleteObjectif(String id) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.delete(
      Uri.parse('$url/api/objectifs/$id'),
      headers: headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur API (${res.statusCode})');
    }
  }

  Future<List<Alerte>> getAlertes() async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.get(Uri.parse('$url/api/alertes'), headers: headers);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => Alerte.fromMap(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Erreur API (${res.statusCode})');
  }

  Future<Alerte> createAlerte(Alerte a) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$url/api/alertes'),
      headers: headers,
      body: jsonEncode(a.toMap()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Alerte.fromMap(data);
    }
    throw Exception('Erreur API (${res.statusCode})');
  }

  Future<void> updateAlerte(Alerte a) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.put(
      Uri.parse('$url/api/alertes/${a.id}'),
      headers: headers,
      body: jsonEncode(a.toMap()),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur API (${res.statusCode})');
    }
  }

  Future<void> deleteAlerte(String id) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.delete(
      Uri.parse('$url/api/alertes/$id'),
      headers: headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur API (${res.statusCode})');
    }
  }

  Future<List<TransactionRecurrente>> getRecurrences() async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res =
        await http.get(Uri.parse('$url/api/recurrences'), headers: headers);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => TransactionRecurrente.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur API (${res.statusCode})');
  }

  Future<TransactionRecurrente> createRecurrence(TransactionRecurrente r) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$url/api/recurrences'),
      headers: headers,
      body: jsonEncode(r.toMap()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return TransactionRecurrente.fromMap(data);
    }
    throw Exception('Erreur API (${res.statusCode})');
  }

  Future<void> updateRecurrence(TransactionRecurrente r) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.put(
      Uri.parse('$url/api/recurrences/${r.id}'),
      headers: headers,
      body: jsonEncode(r.toMap()),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur API (${res.statusCode})');
    }
  }

  Future<void> deleteRecurrence(String id) async {
    final url = await _baseUrl();
    final headers = await _headers();
    final res = await http.delete(
      Uri.parse('$url/api/recurrences/$id'),
      headers: headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur API (${res.statusCode})');
    }
  }
}
