import 'package:planify/struct/appState.dart';
import 'package:planify/database/tables.dart';
import 'package:planify/functions.dart';
import 'package:planify/pages/transactionFilters.dart';
import 'package:planify/struct/settings.dart';
import 'package:planify/widgets/transactionEntries.dart';
import 'package:flutter/material.dart';

class HomeTransactions extends StatelessWidget {
  const HomeTransactions({
    super.key,
    required this.selectedSlidingSelector,
  });
  final int selectedSlidingSelector;
  @override
  Widget build(BuildContext context) {
    SearchFilters searchFilters = SearchFilters(
      expenseIncome:
          appStateSettings["homePageTransactionsListIncomeAndExpenseOnly"] ==
                  true
              ? [
                  if (selectedSlidingSelector == 2) ExpenseIncome.expense,
                  if (selectedSlidingSelector == 3) ExpenseIncome.income
                ]
              : [],
      positiveCashFlow:
          appStateSettings["homePageTransactionsListIncomeAndExpenseOnly"] ==
                  false
              ? selectedSlidingSelector == 2
                  ? false
                  : selectedSlidingSelector == 3
                      ? true
                      : null
              : null,
    );
    int numberOfFutureDays = appStateSettings["futureTransactionDaysHomePage"];
    return TransactionEntries(
      showNumberOfDaysUntilForFutureDates: true,
      renderType: TransactionEntriesRenderType.implicitlyAnimatedNonSlivers,
      showNoResults: false,
      DateTime.now().justDay(monthOffset: -1),
      DateTime.now().justDay(dayOffset: numberOfFutureDays),
      dateDividerColor: Colors.transparent,
      useHorizontalPaddingConstrained: false,
      pastDaysLimitToShow: 7,
      limitPerDay: 50,
      searchFilters: searchFilters,
      enableFutureTransactionsCollapse: false,
    );
  }
}


