import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:tpi2a/Screens/activit%C3%A9.dart';

import 'Login.dart';

class AddActivityPage extends StatefulWidget {
  @override
  _AddActivityPageState createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController numberOfPeopleController = TextEditingController();
  File? selectedImage;
  List<dynamic>? _recognitions;

  final firebase_storage.Reference storageRef =
  firebase_storage.FirebaseStorage.instance.ref().child('activity_images');

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
      );
      print('Model loaded: $res');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> classifyImage(File image) async {
    await loadModel(); // Ensure the model is loaded before classifying
    try {
      var recognitions = await Tflite.runModelOnImage(
        path: image.path,
      );

      setState(() {
        _recognitions = recognitions;
        categoryController.text =
            _recognitions![0]['label'].toString().substring(2);
        selectedImage = image;
      });

      // Read image bytes and encode them to base64
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      print('Base64 Image: $base64Image');
    } catch (e) {
      print('Error classifying image: $e');
      throw Exception('Error classifying image: $e');
    }
  }

  Future<void> saveDataToFirestore() async {
    
  }

  Future<void> uploadActivity(
      String title,
      String category,
      String location,
      double price,
      String numberOfPeople,
      File? image,
      ) async {
    try {
      if (image == null) {
        throw Exception('Image is null');
      }

      // Generate a unique filename for the image
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      firebase_storage.Reference imageRef = storageRef.child(fileName);

      // Upload the image to Firebase Storage
      await imageRef.putFile(image);

      // Get the download URL of the uploaded image
      String imageUrl = await imageRef.getDownloadURL();

      String collectionName = "activite".toLowerCase();

      // Log values before uploading
      print(imageUrl);

     
      await FirebaseFirestore.instance.collection(collectionName).add({
        'title': title ?? '',
        'location': location ?? '',
        'price': price ?? 0.0,
        'category': category ?? '',
        'image': imageUrl, // Store the download URL instead of base64
        'numberofpeople': int.tryParse(numberOfPeople) ?? 0,
        // Add other fields as needed
      });

      print('Activity uploaded successfully');
    } catch (e) {
      print('Title: $title');
      print('Location: $location');
      print('Price: $price');
      print('Category: $category');
      print('Number of People: $numberOfPeople');
      print('Error uploading activity: $e');
      // Handle the error, e.g., show a message to the user
      throw Exception('Error uploading activity: $e');
    }
  }

  Future<void> captureImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        classifyImage(File(pickedFile.path));
        setState(() {
          selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error capturing image: $e');
      // Handle the error, e.g., show a message to the user
    }
  }

  Widget buildImagePickerSection() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        selectedImage != null
            ? Image.file(
          selectedImage!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        )
            : Container(
          height: 200,
          width: double.infinity,
          color: Colors.grey[300],
          child: Icon(
            Icons.camera_alt,
            size: 50,
            color: Colors.grey[600],
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () async {
              await captureImage();
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(16),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildFormSection() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: 'Catégorie (predicté avec IA) : ',
              ),
              TextSpan(
                text: categoryController.text,
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Titre',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: 'Entrer le titre',
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Lieu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextField(
          controller: locationController,
          decoration: InputDecoration(
            hintText: 'Entrer lieu',
          ),
        ),
        SizedBox(height: 20),
        Text(
          'prix',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Entrer prix',
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Nombre de Personne',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextField(
          controller: numberOfPeopleController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Entrer nombre de personne',
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            try {
              if (titleController.text.isEmpty ||
                  locationController.text.isEmpty ||
                  priceController.text.isEmpty ||
                  numberOfPeopleController.text.isEmpty ||
                  selectedImage == null) {
                throw Exception('Veuillez remplir tous les champs obligatoires');
              }
              await saveDataToFirestore();
              await uploadActivity(
                titleController.text,
                categoryController.text,
                locationController.text,
                double.tryParse(priceController.text) ?? 0.0,
                numberOfPeopleController.text,
                selectedImage,
              );
              Navigator.pop(context); 
            } catch (e) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('error'),
                    content: Text(e.toString()),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          },
          style: ElevatedButton.styleFrom(
            primary: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 40),
          ),
          child: Text(
            'Enregister',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    )
    );
  }

  Widget buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
            break;
          case 1:
          // You are already on this page
            break;
          case 2:
          // Navigate to the third page
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: 'Activité',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'Ajouter',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        appBar: AppBar(
          title: Text("Ajouter activité"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildImagePickerSection(),
              buildFormSection(),
            ],
          ),
        ),
        bottomNavigationBar: buildBottomNavigationBar(),
      );
    } catch (e) {
      print('Error building widget: $e');
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }
}
