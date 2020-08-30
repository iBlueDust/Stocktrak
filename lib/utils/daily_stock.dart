class DailyStock {
	final int no;
	final int id;
	final DateTime date;
	final String stockCode;
	final String stockName;
	final String remarks;
	final double previous;
	final double openPrice;
	final double firstTrade;
	final double high;
	final double low;
	final double close;
	final double change;
	final double volume;
	final double value;
	final double frequency;
	final double indexIndividual;
	final double offer;
	final double offerVolume;
	final double bid;
	final double bidVolume;
	final double listedShares;
	final double tradebleShares;
	final double weightForIndex;
	final double foreignSell;
	final double foreignBuy;
	final DateTime delistingDate;
	final double nonRegularVolume;
	final double nonRegularValue;
	final double nonRegularFrequency;
	final dynamic persen;
	final dynamic percentage;

	DailyStock({
		this.no,
		this.id,
		this.date,
		this.stockCode,
		this.stockName,
		this.remarks,
		this.previous,
		this.openPrice,
		this.firstTrade,
		this.high,
		this.low,
		this.close,
		this.change,
		this.volume,
		this.value,
		this.frequency,
		this.indexIndividual,
		this.offer,
		this.offerVolume,
		this.bid,
		this.bidVolume,
		this.listedShares,
		this.tradebleShares,
		this.weightForIndex,
		this.foreignSell,
		this.foreignBuy,
		this.delistingDate,
		this.nonRegularVolume,
		this.nonRegularValue,
		this.nonRegularFrequency,
		this.persen,
		this.percentage,
	});

	DailyStock.fromJson(Map<String, dynamic> obj)
		: this(
		no: obj['No'],
		id: obj['IDStockSummary'],
		date: DateTime.tryParse(obj['Date']),
		stockCode: obj['StockCode'],
		stockName: obj['StockName'],
		remarks: obj['Remarks'],
		previous: obj['Previous'],
		openPrice: obj['OpenPrice'],
		firstTrade: obj['FirstTrade'],
		high: obj['High'],
		low: obj['Low'],
		close: obj['Close'],
		change: obj['Change'],
		volume: obj['Volume'],
		value: obj['Value'],
		frequency: obj['Frequency'],
		indexIndividual: obj['IndexIndividual'],
		offer: obj['Offer'],
		offerVolume: obj['OfferVolume'],
		bid: obj['Bid'],
		bidVolume: obj['BidVolume'],
		listedShares: obj['ListedShares'],
		tradebleShares: obj['TradebleShares'],
		weightForIndex: obj['WeightForIndex'],
		foreignSell: obj['ForeignSell'],
		foreignBuy: obj['ForeignBuy'],
		delistingDate: DateTime.tryParse(obj['DelistingDate']),
		nonRegularVolume: obj['NonRegularVolume'],
		nonRegularValue: obj['NonRegularValue'],
		nonRegularFrequency: obj['NonRegularFrequency'],
		persen: obj['persen'],
		percentage: obj['percentage'],
	);

	Map<String, dynamic> toJson() => {
		'No': no,
		'IDStockSummary': id,
		'Date': date?.toIso8601String(),
		'StockCode': stockCode,
		'StockName': stockName,
		'Remarks': remarks,
		'Previous': previous,
		'OpenPrice': openPrice,
		'FirstTrade': firstTrade,
		'High': high,
		'Low': low,
		'Close': close,
		'Change': change,
		'Volume': volume,
		'Value': value,
		'Frequency': frequency,
		'IndexIndividual': indexIndividual,
		'Offer': offer,
		'OfferVolume': offerVolume,
		'Bid': bid,
		'BidVolume': bidVolume,
		'ListedShares': listedShares,
		'TradebleShares': tradebleShares,
		'WeightForIndex': weightForIndex,
		'ForeignSell': foreignSell,
		'ForeignBuy': foreignBuy,
		'DelistingDate': delistingDate?.toIso8601String(),
		'NonRegularVolume': nonRegularVolume,
		'NonRegularValue': nonRegularValue,
		'NonRegularFrequency': nonRegularFrequency,
		'persen': persen,
		'percentage': percentage,
	};
}
