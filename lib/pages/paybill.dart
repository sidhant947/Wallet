import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PayBill extends StatelessWidget {
  PayBill({super.key});

  final List<Widget> banks = [
    const AxisScreen(),
    const IciciScreen(),
    const AubankScreen(),
    const AmexScreen(),
    const IdfcScreen()
  ];

  final List<String> bankName = ['Axis', 'ICICI', 'AU BANK', 'Amex', 'IDFC'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pay Bills by upi",
          style: TextStyle(fontFamily: 'Bebas'),
        ),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: ListView.builder(
          itemCount: banks.length,
          // ignore: avoid_types_as_parameter_names
          itemBuilder: (BuildContext, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => banks[index]),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      colors: [Colors.cyan, Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      tileMode: TileMode.repeated, // This repeats the gradient
                    ),
                  ),
                  height: 150,
                  child: Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        bankName[index].toString(),
                        style: const TextStyle(
                          fontSize: 70,
                        ),
                      ),
                      Divider(
                        thickness: 5,
                        color: Colors.white,
                      )
                    ],
                  )),
                ),
              ),
            );
          }),
    );
  }
}

// Axis

class AxisScreen extends StatefulWidget {
  const AxisScreen({super.key});

  @override
  _AxisScreenState createState() => _AxisScreenState();
}

class _AxisScreenState extends State<AxisScreen> {
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _secondController = TextEditingController();

  Future<void> launchUrlCustom(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Axis Bank'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
                maxLength: 10,
                controller: _firstController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter 10 digit mobile number',
                )),
            const SizedBox(height: 16.0),
            TextField(
                maxLength: 4,
                controller: _secondController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter Last 4 Digit of Card',
                )),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {
                final firstValue = _firstController.text;
                final secondValue = _secondController.text;

                launchUrlCustom(Uri.parse(
                    'upi://pay?pa=CC.91$firstValue$secondValue@axisbank&pn=Axis&cu=INR'));
              },
              child: Container(
                width: 150,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1)),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {
                final firstValue = _firstController.text;
                final secondValue = _secondController.text;

                String qrurl =
                    'upi://pay?pa=CC.91$firstValue$secondValue@axisbank&pn=Axis&cu=INR';

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GetQR(qrurl: qrurl)));
              },
              child: Container(
                width: 150,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1)),
                child: const Text(
                  'Get QR Code',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Please Check Name on Payment Page before Paying, We are not Liable for any Wrong Payments",
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    super.dispose();
  }
}

// amex

class AmexScreen extends StatefulWidget {
  const AmexScreen({super.key});

  @override
  _AmexScreenState createState() => _AmexScreenState();
}

class _AmexScreenState extends State<AmexScreen> {
  final TextEditingController _firstController = TextEditingController();
  Future<void> launchUrlCustom(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amex Bank'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              maxLength: 15,
              controller: _firstController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter 15 digit Card number',
              ),
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {
                final firstValue = _firstController.text;
                launchUrlCustom(Uri.parse(
                    'upi://pay?pa=AEBC$firstValue@SC&pn=AMEX&cu=INR'));
              },
              child: Container(
                width: 150,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1)),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () {
                final firstValue = _firstController.text;

                String qrurl = 'upi://pay?pa=AEBC$firstValue@SC&pn=AMEX&cu=INR';

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GetQR(qrurl: qrurl)));
              },
              child: Container(
                width: 150,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1)),
                child: const Text(
                  'Get QR Code',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            const Text(
              "Please Check Name on Payment Page before Paying, We are not Liable for any Wrong Payments",
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstController.dispose();
    super.dispose();
  }
}

// icici

class IciciScreen extends StatefulWidget {
  const IciciScreen({super.key});

  @override
  _IciciScreenState createState() => _IciciScreenState();
}

class _IciciScreenState extends State<IciciScreen> {
  final TextEditingController _firstController = TextEditingController();

  Future<void> launchUrlCustom(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICICI Bank'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              maxLength: 16,
              controller: _firstController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter 16 digit Card number',
              ),
            ),
            const SizedBox(height: 16.0),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {
                final firstValue = _firstController.text;
                launchUrlCustom(Uri.parse(
                    'upi://pay?pa=ccpay.$firstValue@icici&pn=ICICI&cu=INR'));
              },
              child: Container(
                width: 150,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1)),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () {
                final firstValue = _firstController.text;

                String qrurl =
                    'upi://pay?pa=ccpay.$firstValue@icici&pn=ICICI&cu=INR';

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GetQR(qrurl: qrurl)));
              },
              child: Container(
                width: 150,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1)),
                child: const Text(
                  'Get QR Code',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            const Text(
              "Please Check Name on Payment Page before Paying, We are not Liable for any Wrong Payments",
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstController.dispose();
    super.dispose();
  }
}

//idfc

class IdfcScreen extends StatefulWidget {
  const IdfcScreen({super.key});

  @override
  _IdfcScreenState createState() => _IdfcScreenState();
}

class _IdfcScreenState extends State<IdfcScreen> {
  final TextEditingController _firstController = TextEditingController();

  Future<void> launchUrlCustom(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idfc Bank'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              maxLength: 16,
              controller: _firstController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter 16 digit Card number',
              ),
            ),
            const SizedBox(height: 16.0),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {
                final firstValue = _firstController.text;

                launchUrlCustom(Uri.parse(
                    'upi://pay?pa=$firstValue.cc@idfcbank&pn=IDFC&cu=INR'));
              },
              child: Container(
                width: 150,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1)),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () {
                final firstValue = _firstController.text;

                String qrurl =
                    'upi://pay?pa=$firstValue.cc@idfcbank&pn=IDFC&cu=INR';

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GetQR(qrurl: qrurl)));
              },
              child: Container(
                width: 150,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1)),
                child: const Text(
                  'Get QR Code',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            const Text(
              "Please Check Name on Payment Page before Paying, We are not Liable for any Wrong Payments",
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstController.dispose();
    super.dispose();
  }
}

//Au bank

class AubankScreen extends StatefulWidget {
  const AubankScreen({super.key});

  @override
  _AubankScreenState createState() => _AubankScreenState();
}

class _AubankScreenState extends State<AubankScreen> {
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _secondController = TextEditingController();

  Future<void> launchUrlCustom(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AU Bank'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              maxLength: 10,
              controller: _firstController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter 10 digit mobile number',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              maxLength: 4,
              controller: _secondController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Last 4 Digit of Card',
              ),
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {
                final firstValue = _firstController.text;
                final secondValue = _secondController.text;

                launchUrlCustom(Uri.parse(
                    'upi://pay?pa=AUCC$firstValue$secondValue@AUBANK&pn=AU Bank&cu=INR'));
              },
              child: Container(
                width: 150,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1)),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () {
                final firstValue = _firstController.text;
                final secondValue = _secondController.text;

                String qrurl =
                    'upi://pay?pa=AUCC$firstValue$secondValue@AUBANK&pn=AU Bank&cu=INR';

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GetQR(qrurl: qrurl)));
              },
              child: Container(
                width: 150,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1)),
                child: const Text(
                  'Get QR Code',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            const Text(
              "Please Check Name on Payment Page before Paying, We are not Liable for any Wrong Payments",
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    super.dispose();
  }
}

class GetQR extends StatelessWidget {
  const GetQR({super.key, required this.qrurl});
  final String qrurl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pay By QR"),
      ),
      body: Center(
        child: BarcodeWidget(
          data: qrurl,
          barcode: Barcode.qrCode(),
          width: 250,
          height: 250,
          color: Colors.white,
        ),
      ),
    );
  }
}
