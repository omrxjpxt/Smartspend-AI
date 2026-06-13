import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:printing/printing.dart';
import '../domain/entities/app_transaction.dart';
import '../domain/entities/goal.dart';
import '../domain/entities/investment.dart';

class MonthlyPdfService {
  Future<void> generateAndSaveMonthlyStatement({
    required List<AppTransaction> transactions,
    required List<Goal> goals,
    required List<Investment> investments,
    required DateTime monthDate,
    required String userName,
    required String userEmail,
    String? aiSummary,
  }) async {
    final bytes = await generateStatementBytes(
      transactions: transactions,
      goals: goals,
      investments: investments,
      monthDate: monthDate,
      userName: userName,
      userEmail: userEmail,
      aiSummary: aiSummary,
    );

    final monthString = DateFormat('MMMM yyyy').format(monthDate);
    final filename = 'SmartSpend_Statement_${DateFormat('MMMM_yyyy').format(monthDate)}.pdf';

    debugPrint('--- PDF EXPORT LOG ---');
    debugPrint('Transactions included: ${transactions.length}');
    debugPrint('Month selected: $monthString');
    debugPrint('File generated: $filename');

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = filename;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$filename');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    }
  }

  Future<Uint8List> generateStatementBytes({
    required List<AppTransaction> transactions,
    required List<Goal> goals,
    required List<Investment> investments,
    required DateTime monthDate,
    required String userName,
    required String userEmail,
    String? aiSummary,
  }) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    final pw.ThemeData theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);
    final monthString = DateFormat('MMMM yyyy').format(monthDate);
    final generatedDate = DateFormat('d MMM yyyy • h:mm a').format(DateTime.now());
    final statementId = 'STMT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // Strict Computations
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final tx in transactions) {
      if (tx.type == 'Income' || tx.type == 'Balance Added') {
        totalIncome += tx.amount;
      } else if (tx.type == 'Expense') {
        totalExpenses += tx.amount;
      }
    }

    double savingsRate = 0;
    if (totalIncome > 0) {
      savingsRate = ((totalIncome - totalExpenses) / totalIncome) * 100;
    }

    final totalInvested = investments.fold(0.0, (sum, i) => sum + i.currentValue);
    final activeGoals = goals.where((g) => g.currentAmount < g.targetAmount).length;

    // AI Sanitization
    String? cleanAiSummary;
    if (aiSummary != null && aiSummary.isNotEmpty) {
      final lower = aiSummary.toLowerCase();
      if (!lower.contains('timeout') && 
          !lower.contains('unavailable') && 
          !lower.contains('too many requests') &&
          !lower.contains('error')) {
        cleanAiSummary = aiSummary;
      }
    }

    // PAGE 1: EXECUTIVE DASHBOARD
    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: -math.pi / 4,
                    child: pw.Text('CONFIDENTIAL', style: pw.TextStyle(fontSize: 60, color: PdfColors.grey200)),
                  ),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeader(userName, userEmail, monthString, generatedDate, statementId, logoImage),
                  pw.SizedBox(height: 20),
                  _buildExecutiveDashboard(totalIncome, totalExpenses, totalIncome - totalExpenses, savingsRate, totalInvested, activeGoals, currencyFormatter),
                  pw.Spacer(),
                  _buildFooter(context.pageNumber, context.pagesCount, statementId),
                ],
              ),
            ],
          );
        },
      ),
    );

    // PAGE 2: FINANCIAL INSIGHTS
    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: -math.pi / 4,
                    child: pw.Text('CONFIDENTIAL', style: pw.TextStyle(fontSize: 60, color: PdfColors.grey200)),
                  ),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeader(userName, userEmail, monthString, generatedDate, statementId, logoImage, hideDetails: true),
                  pw.SizedBox(height: 20),
                  _buildFinancialInsights(cleanAiSummary),
                  pw.Spacer(),
                  _buildFooter(context.pageNumber, context.pagesCount, statementId),
                ],
              ),
            ],
          );
        },
      ),
    );

    // PAGE 3+: PORTFOLIO & TRANSACTIONS
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(userName, userEmail, monthString, generatedDate, statementId, logoImage, hideDetails: true),
        footer: (context) => _buildFooter(context.pageNumber, context.pagesCount, statementId),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildGoalsSection(goals, currencyFormatter),
          pw.SizedBox(height: 30),
          _buildInvestmentsSection(investments, currencyFormatter),
          pw.SizedBox(height: 30),
          _buildCategoryAnalysis(transactions, currencyFormatter),
          pw.SizedBox(height: 30),
          _buildTransactionTable(transactions, currencyFormatter),
        ],
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildHeader(String name, String email, String period, String generated, String statementId, pw.MemoryImage? logo, {bool hideDetails = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                if (logo != null) ...[
                  pw.Image(logo, width: 40, height: 40),
                  pw.SizedBox(width: 10),
                ],
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SmartSpend AI', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple900)),
                    pw.SizedBox(height: 2),
                    pw.Text('Official Financial Statement', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            if (!hideDetails)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text(email, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9)),
                  pw.SizedBox(height: 6),
                  pw.Text('Period: $period', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('ID: $statementId', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8)),
                  pw.Text('Generated: $generated', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8)),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.deepPurple200, thickness: 1.5),
      ],
    );
  }

  pw.Widget _buildExecutiveDashboard(double income, double expenses, double savings, double savingsRate, double totalInvested, int activeGoals, NumberFormat fmt) {
    String healthStatus = 'Needs Attention';
    PdfColor healthColor = PdfColors.red800;
    if (savingsRate > 20) {
      healthStatus = 'Healthy';
      healthColor = PdfColors.green800;
    } else if (savingsRate > 5) {
      healthStatus = 'Stable';
      healthColor = PdfColors.orange800;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('EXECUTIVE DASHBOARD', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 10),
        
        // 6-CARD KPI GRID
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _statCard('Total Income', fmt.format(income), PdfColors.green800),
            _statCard('Total Expenses', fmt.format(expenses), PdfColors.red800),
            _statCard('Net Savings', fmt.format(savings), PdfColors.blue800),
            _statCard('Savings Rate', '${savingsRate.toStringAsFixed(1)}%', PdfColors.deepPurple800),
            _statCard('Total Investments', fmt.format(totalInvested), PdfColors.indigo800),
            _statCard('Active Goals', '$activeGoals', PdfColors.teal800),
          ],
        ),

        pw.SizedBox(height: 20),
        
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                height: 180,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Income vs Expenses', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple800)),
                    pw.SizedBox(height: 10),
                    pw.Expanded(
                      child: pw.Chart(
                        grid: pw.CartesianGrid(
                          xAxis: pw.FixedAxis.fromStrings(const ['Income', 'Expenses'], ticks: true),
                          yAxis: pw.FixedAxis(
                            [0, math.max(income, expenses) / 2, math.max(income, expenses)],
                            format: (v) => (v / 1000).toStringAsFixed(0) + 'k',
                          ),
                        ),
                        datasets: [
                          pw.BarDataSet(
                            color: PdfColors.green600,
                            width: 30,
                            legend: 'Income',
                            data: [pw.PointChartValue(0, income), pw.PointChartValue(1, 0)],
                          ),
                          pw.BarDataSet(
                            color: PdfColors.red600,
                            width: 30,
                            legend: 'Expenses',
                            data: [pw.PointChartValue(0, 0), pw.PointChartValue(1, expenses)],
                          ),
                        ],
                      )
                    )
                  ]
                )
              ),
            ),
            pw.SizedBox(width: 15),
            pw.Expanded(
              flex: 1,
              child: pw.Container(
                height: 180,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.deepPurple50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.deepPurple200),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Financial Health', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple800)),
                    pw.SizedBox(height: 16),
                    pw.Text(healthStatus, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: healthColor)),
                    pw.SizedBox(height: 16),
                    pw.Text('Based on a savings rate of ${savingsRate.toStringAsFixed(1)}% this period.', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ]
                )
              ),
            )
          ]
        ),
      ]
    );
  }

  pw.Widget _buildFinancialInsights(String? aiSummary) {
    if (aiSummary == null || aiSummary.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Center(
          child: pw.Text(
            'No sufficient data available for this period to generate insights.',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 12),
          ),
        ),
      );
    }

    // Parse the summary assuming Markdown bullet points and headers
    final lines = aiSummary.split('\n');
    final widgets = <pw.Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: pw.TextStyle(fontSize: 12, color: PdfColors.deepPurple800)),
                pw.Expanded(
                  child: pw.Text(line.substring(2).trim(), style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5, color: PdfColors.grey900)),
                ),
              ],
            ),
          ),
        );
      } else {
        // Treat as a header
        final text = line.replaceAll('#', '').replaceAll('**', '').trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
            child: pw.Text(text.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple800)),
          ),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('FINANCIAL INSIGHTS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 10),
        ...widgets,
      ]
    );
  }

  pw.Widget _buildGoalsSection(List<Goal> goals, NumberFormat fmt) {
    if (goals.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ACTIVE GOALS PROGRESS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 10),
        ...goals.map((g) {
          final remaining = g.targetAmount - g.currentAmount;
          int monthsRemaining = 0;
          if (g.monthlyContribution > 0 && remaining > 0) {
            monthsRemaining = (remaining / g.monthlyContribution).ceil();
          }
          final progressPercent = (g.progress.clamp(0.0, 1.0) * 100).toStringAsFixed(0);

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${g.emoji} ${g.title}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('$progressPercent% Completed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple600, fontSize: 10)),
                  ]
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  height: 6,
                  width: double.infinity,
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.all(pw.Radius.circular(3))),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 450 * g.progress.clamp(0.0, 1.0), // approx width mapping
                        height: 6,
                        decoration: const pw.BoxDecoration(color: PdfColors.deepPurple500, borderRadius: pw.BorderRadius.all(pw.Radius.circular(3))),
                      )
                    ]
                  )
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Saved: ${fmt.format(g.currentAmount)}', style: const pw.TextStyle(color: PdfColors.grey800, fontSize: 10)),
                    pw.Text('Target: ${fmt.format(g.targetAmount)}', style: const pw.TextStyle(color: PdfColors.grey800, fontSize: 10)),
                  ]
                ),
                pw.SizedBox(height: 4),
                if (monthsRemaining > 0)
                  pw.Text('At current savings rate, you will reach this goal in $monthsRemaining months.', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 9, fontStyle: pw.FontStyle.italic)),
              ],
            )
          );
        }),
      ]
    );
  }

  pw.Widget _buildInvestmentsSection(List<Investment> investments, NumberFormat fmt) {
    if (investments.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('INVESTMENT PORTFOLIO', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Asset', 'Platform', 'Type', 'Invested', 'Current', 'Gain/Loss', 'Return'],
          data: investments.map((i) {
            final profitLoss = i.currentValue - i.investedAmount;
            final profitLossPercent = i.investedAmount > 0 ? (profitLoss / i.investedAmount) * 100 : 0.0;
            return [
              i.assetName, 
              i.platform, 
              i.investmentType, 
              fmt.format(i.investedAmount),
              fmt.format(i.currentValue),
              fmt.format(profitLoss),
              '${profitLossPercent > 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(1)}%'
            ];
          }).toList(),
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple900),
          cellAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellPadding: const pw.EdgeInsets.all(6),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        ),
      ]
    );
  }

  pw.Widget _buildCategoryAnalysis(List<AppTransaction> transactions, NumberFormat fmt) {
    final expenses = transactions.where((t) => t.type == 'Expense').toList();
    if (expenses.isEmpty) return pw.SizedBox();

    final Map<String, double> categoryTotals = {};
    double totalExp = 0;
    for (var e in expenses) {
      categoryTotals[e.category ?? 'Other'] = (categoryTotals[e.category ?? 'Other'] ?? 0) + e.amount;
      totalExp += e.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      PdfColors.deepPurple400,
      PdfColors.purple500,
      PdfColors.indigo400,
      PdfColors.blue400,
      PdfColors.cyan400,
      PdfColors.teal400,
      PdfColors.green400,
      PdfColors.grey400,
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('EXPENSE ANALYSIS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.SizedBox(
                height: 120,
                child: pw.Chart(
                  grid: pw.PieGrid(),
                  datasets: List.generate(sortedCategories.length, (index) {
                    final c = sortedCategories[index];
                    return pw.PieDataSet(
                      value: c.value,
                      legend: '${c.key} (${((c.value / totalExp) * 100).toStringAsFixed(0)}%)',
                      color: colors[index % colors.length],
                    );
                  }),
                ),
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 1,
              child: pw.TableHelper.fromTextArray(
                headers: ['Category', 'Amount', '%'],
                data: sortedCategories.map((c) => [
                  c.key, 
                  fmt.format(c.value), 
                  '${((c.value / totalExp) * 100).toStringAsFixed(1)}%'
                ]).toList(),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple700),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.all(6),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              ),
            ),
          ]
        )
      ]
    );
  }

  pw.Widget _buildTransactionTable(List<AppTransaction> transactions, NumberFormat fmt) {
    if (transactions.isEmpty) {
      return pw.Text('No transactions found for this period.', style: const pw.TextStyle(color: PdfColors.grey600));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('DETAILED TRANSACTIONS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Category', 'Description', 'Type', 'Amount'],
          data: transactions.map((t) => [
            DateFormat('dd MMM').format(t.createdAt),
            t.category ?? '-',
            t.title,
            t.type,
            fmt.format(t.amount)
          ]).toList(),
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
          cellAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellPadding: const pw.EdgeInsets.all(6),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        ),
      ]
    );
  }

  pw.Widget _statCard(String title, String value, PdfColor valueColor) {
    return pw.Container(
      width: 155, // Increased width for 6-card grid on A4
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(int pageNumber, int pagesCount, String statementId) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated securely by SmartSpend AI', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.Text('ID: $statementId', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
            pw.Text('Page $pageNumber of $pagesCount', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
      ]
    );
  }
}
