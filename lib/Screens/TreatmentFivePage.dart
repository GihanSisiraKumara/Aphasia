import 'package:flutter/material.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';

class TreatmentFivePage extends StatefulWidget {
  final String description;
  const TreatmentFivePage({super.key, this.description = ''});

  @override
  State<TreatmentFivePage> createState() => _TreatmentFivePageState();
}

class _TreatmentFivePageState extends State<TreatmentFivePage> {
  List<Product> productList = [
    Product('assets/images/play_ground.jpg', 'Play Ground', 100,
        " There are five people in the picture. Two boys are sitting on swings. A woman in a white dress is standing between the boys. She looks happy and is holding one swing chain. In the background, two people are sitting on a bench. The scene is outdoors on green grass. The sky is blue with some clouds. It appears to be a sunny day in a park or playground."),
    Product('assets/images/dog.png', 'SS Gamage', 100,
        " I'm highly motivated 25-year-old Computer Science undergraduate with a passion for full-stack development. Currently, we are developing a PDF converter app, showcasing skills in Flutter and Dart. Eager to refine our skills and make a meaningful impact, I'm aims to leverage our technical knowledge in professional settings.We hope that this app give you special features."),
    // Product('assets/images/sisira.jpg', 'Sisira', 100, 'sd'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 250, 251),
        centerTitle: true,
        title: const Text(
          'Level 5',
          style: TextStyle(
            fontSize: 22,
            color: Color.fromARGB(255, 244, 242, 242),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          style: ButtonStyle(
            iconSize: WidgetStateProperty.all<double>(30),
            iconColor: WidgetStateProperty.all<Color>(
                const Color.fromARGB(255, 252, 251, 251)),
            backgroundColor: WidgetStateProperty.all<Color>(
                const Color.fromARGB(255, 64, 183, 37)),
          ),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 216, 255, 166),
                Color.fromARGB(255, 33, 180, 82)
              ],
            ),
          ),
        ),
      ),
      body: SizedBox(
        height: 730,
        child: ScrollSnapList(
          itemBuilder: _buildListItem,
          itemCount: productList.length,
          itemSize: 350,
          onItemFocus: (index) {},
          dynamicItemSize: true,
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    Product product = productList[index];
    return SizedBox(
      width: 350,
      height: 250,
      child: Card(
        elevation: 12,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
                child: Image.asset(
                  product.imagePath,
                  fit: BoxFit.cover,
                  width: 230,
                  height: 270,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Try to describe the image',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        product.description,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //       builder: (context) => const FeedbackBord(
                        //             title: '',
                        //           )),
                        // );
                      },
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          disabledForegroundColor:
                              Colors.grey.withOpacity(0.38),
                          shadowColor: Colors.red,
                          elevation: 5,
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      child: const Text('Get in Touch'),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Product {
  final String imagePath;
  final String title;
  final double cost;
  final String description;

  Product(this.imagePath, this.title, this.cost, this.description);
}
