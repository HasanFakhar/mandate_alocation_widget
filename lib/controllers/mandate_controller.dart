import '../models/portfolio_model.dart';
import '../models/mandate_model.dart';
import 'package:get/get.dart';


class MandateController extends GetxController {



  // static const String portfolioApiUrl = 'https://your-api.example.com/portfolio'; // placeholder URL
  // static const String mandateApiUrl = 'https://your-api.example.com/mandates'; // placeholder URL



  final RxList<MandateModel> mandates = RxList<MandateModel>([]);
  final Rx<PortfolioData?> portfolioData = Rx<PortfolioData?>(null);
  double totalPortfolioValue  = 0.0;
  Map<String, double> marketValueByAssetClass = <String, double>{};
  Map<String, double> allocationByAssetClass  = <String, double>{};



  @override
  void onInit() {
    super.onInit();
    _loadDummyData();  
  }

  void _loadDummyData() {
    _loadMandatesFromList([
      {'AssetName': 'Liquiditeiten', 'Min': 0.0,  'Max': 100.0, 'Strategic': 5.0},
      {'AssetName': 'Aandelen',     'Min': 10.0, 'Max': 80.0, 'Strategic': 65.0},
      {'AssetName': 'Obligaties',   'Min': 10.0, 'Max': 80.0, 'Strategic': 25.0},
      {'AssetName': 'Vastgoed',     'Min': 5.0,  'Max': 100.0, 'Strategic': 10.0},
    ]);

    _loadPortfolioFromJson({
      'Table': [
        {
          'FullSecurityName': 'Rekening courant (EUR)',
          'LocalCurrencyCode': 'eu',
          'LocalCurrencyName': 'Euro',
          'PortfolioCode': '02060000636479s1',
          'ReportDate': '2026-05-26T00:00:00',
          'ReportingCurrencyCode': 'eu',
          'AssetClassName': 'Liquiditeiten',
          'LocalCurrencyISOCode': 'EUR',
          'MarketValue': 18.91,
        },
        {
          'FullSecurityName': 'UBS Fiduciary Call (EUR)',
          'LocalCurrencyCode': 'eu',
          'LocalCurrencyName': 'Euro',
          'PortfolioCode': '02060000636479s1',
          'ReportDate': '2026-05-26T00:00:00',
          'ReportingCurrencyCode': 'eu',
          'AssetClassName': 'Liquiditeiten',
          'LocalCurrencyISOCode': 'EUR',
          'MarketValue': 13000.0,
        },
        {
          'FullSecurityName': 'iShares MSCI World ETF',
          'LocalCurrencyCode': 'eu',
          'LocalCurrencyName': 'Euro',
          'PortfolioCode': '02060000636479s1',
          'ReportDate': '2026-05-26T00:00:00',
          'ReportingCurrencyCode': 'eu',
          'AssetClassName': 'Aandelen',
          'LocalCurrencyISOCode': 'EUR',
          'MarketValue': 42500.0,
        },
        {
          'FullSecurityName': 'Vanguard EM Equity',
          'LocalCurrencyCode': 'eu',
          'LocalCurrencyName': 'Euro',
          'PortfolioCode': '02060000636479s1',
          'ReportDate': '2026-05-26T00:00:00',
          'ReportingCurrencyCode': 'eu',
          'AssetClassName': 'Aandelen',
          'LocalCurrencyISOCode': 'EUR',
          'MarketValue': 8750.0,
        },
        {
          'FullSecurityName': 'Dutch Gov Bond 2031',
          'LocalCurrencyCode': 'eu',
          'LocalCurrencyName': 'Euro',
          'PortfolioCode': '02060000636479s1',
          'ReportDate': '2026-05-26T00:00:00',
          'ReportingCurrencyCode': 'eu',
          'AssetClassName': 'Obligaties',
          'LocalCurrencyISOCode': 'EUR',
          'MarketValue': 27000.0,
        },
        {
          'FullSecurityName': 'EUR IG Corp Bond Fund',
          'LocalCurrencyCode': 'eu',
          'LocalCurrencyName': 'Euro',
          'PortfolioCode': '02060000636479s1',
          'ReportDate': '2026-05-26T00:00:00',
          'ReportingCurrencyCode': 'eu',
          'AssetClassName': 'Obligaties',
          'LocalCurrencyISOCode': 'EUR',
          'MarketValue': 11200.0,
        },
        {
          'FullSecurityName': 'CBRE Global REIT',
          'LocalCurrencyCode': 'eu',
          'LocalCurrencyName': 'Euro',
          'PortfolioCode': '02060000636479s1',
          'ReportDate': '2026-05-26T00:00:00',
          'ReportingCurrencyCode': 'eu',
          'AssetClassName': 'Vastgoed',
          'LocalCurrencyISOCode': 'EUR',
          'MarketValue': 9300.0,
        },
      ],
      'Table1': [
        {'ColumnValue': 'Liquiditeiten', 'MarketValue': 13018.91, 'Percentage': 100.0, 'Yield': null},
 
      ],
    });
  }


  void _loadMandatesFromList(List<Map<String, dynamic>> rawList) {
    mandates.assignAll(rawList.map((json) => MandateModel(
      assetName: json['AssetName']  as String?,
      min: (json['Min']  as num?)?.toDouble(),
      max: (json['Max']  as num?)?.toDouble(),
      strategic: (json['Strategic'] as num?)?.toDouble(),
    )));
  }

  void _loadPortfolioFromJson(Map<String, dynamic> rawJson) {
    assert(rawJson.containsKey('Table'),'API response missing "Table"');
    assert(rawJson.containsKey('Table1'), 'API response missing "Table1"');

    portfolioData.value = PortfolioData.fromJson(rawJson);
    _runCalculations();
  }


  void _runCalculations() {
    final data = portfolioData.value;
    if (data == null) return;

    totalPortfolioValue = _calculateTotalValue(data.holdings);
    marketValueByAssetClass = _groupAndAggregate(data.holdings);
    allocationByAssetClass = _calculateAllocations(
      marketValueByAssetClass,
      totalPortfolioValue,
    );
  }

  double _calculateTotalValue(List<PortfolioHolding> holdings) =>
      holdings.fold(0.0, (sum, h) => sum + h.marketValue);

  Map<String, double> _groupAndAggregate(List<PortfolioHolding> holdings) {
    final Map<String, double> result = {};
    for (final h in holdings) {
      result[h.assetClassName] = (result[h.assetClassName] ?? 0.0) + h.marketValue;
    }
    return result;
  }

  Map<String, double> _calculateAllocations(
    Map<String, double> mvByClass,
    double total,
  ) {
    if (total == 0) return {for (final k in mvByClass.keys) k: 0.0};
    return mvByClass.map((cls, mv) => MapEntry(cls, (mv / total) * 100));
  }


  MandateModel? mandateFor(String assetName) =>
      mandates.firstWhereOrNull((m) => m.assetName == assetName);

  double actualAllocation(String assetName) =>
      allocationByAssetClass[assetName] ?? 0.0;

  double marketValue(String assetName) =>
      marketValueByAssetClass[assetName] ?? 0.0;


  bool isWithinMandate(String assetName) {
    final m = mandateFor(assetName);
    if (m == null) return false;
    final actual = actualAllocation(assetName);
    return actual >= (m.min ?? 0) && actual <= (m.max ?? 100);
  }
  

}