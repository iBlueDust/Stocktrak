import 'dart:io';

import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

import 'package:stocktrak/utils/money.dart';

/* Future<Money> scrapeStockValue(String code) async {
  final browser = await puppeteer.launch();
  final page = await browser.newPage();
  const selector = '.IsqQVc.NprOob.XcVN5d';

  await page.goto('https://www.google.com/search?q=IDX%3A+$code');
  await page.waitForSelector(
    selector,
    visible: true,
    timeout: Duration(seconds: 20),
  );

  final text = await page.evaluate('sel => document.querySelector(sel).innerText', args: [selector]);

  return Money.fromDouble(double.parse(text.replaceAll(',', '.')));
} */

Future<Money> scrapeStockValue(String code) async {
  final uri = Uri.parse('https://www.google.com/search?q=IDX%3A+$code&hl=en');
  final response = await http.Client().get(uri);

  if (response.statusCode == 200) {
    final document = html.parse(response.body);
    var text = document.querySelector('.BNeawe.iBp4i.AP7Wnd').text;
    text = text.substring(0, text.indexOf(' '));

    return Money.fromDouble(double.parse(text.replaceAll(',', '')));
  } else {
    throw HttpException(response.reasonPhrase, uri: uri);
  }
}
