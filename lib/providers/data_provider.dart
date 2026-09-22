import 'package:flutter/material.dart';
import '../models/domain.dart';
import '../models/time_entry.dart';
import '../models/goal.dart';
import '../models/saving.dart';
import '../models/meeting.dart';
import '../models/finance_transaction.dart';
import '../models/finance_category.dart';
import '../models/publication.dart';
import '../models/reminder.dart';
import '../services/store.dart';

class DataProvider extends ChangeNotifier {
  List<Domain> domains = [];
  List<TimeEntry> entries = [];
  List<Goal> goals = [];
  List<Saving> savings = [];
  List<Meeting> meetings = [];
  List<FinanceTransaction> financeTransactions = [];
  List<FinanceCategory> financeCategories = [];
  List<Publication> publications = [];
  List<Reminder> reminders = [];

  bool loading = true;

  DataProvider() {
    loadAll();
  }

  Future<void> loadAll() async {
    loading = true;
    notifyListeners();
    domains = await Store.loadDomains();
    entries = await Store.loadEntries();
    goals = await Store.loadGoals();
    savings = await Store.loadSavings();
    meetings = await Store.loadMeetings();
    financeTransactions = await Store.loadFinanceTransactions();
    financeCategories = await Store.loadFinanceCategories();
    publications = await Store.loadPublications();
    reminders = await Store.loadReminders();
    loading = false;
    notifyListeners();
  }

  Future<void> saveEntries() async {
    await Store.saveEntries(entries);
    notifyListeners();
  }

  Future<void> saveGoals() async {
    await Store.saveGoals(goals);
    notifyListeners();
  }

  Future<void> saveSavings() async {
    await Store.saveSavings(savings);
    notifyListeners();
  }

  Future<void> saveMeetings() async {
    await Store.saveMeetings(meetings);
    notifyListeners();
  }

  Future<void> saveFinanceTransactions() async {
    await Store.saveFinanceTransactions(financeTransactions);
    notifyListeners();
  }

  Future<void> saveFinanceCategories() async {
    await Store.saveFinanceCategories(financeCategories);
    notifyListeners();
  }

  Future<void> savePublications() async {
    await Store.savePublications(publications);
    notifyListeners();
  }

  Future<void> saveReminders() async {
    await Store.saveReminders(reminders);
    notifyListeners();
  }
}