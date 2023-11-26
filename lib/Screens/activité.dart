import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tpi2a/Screens/Login.dart';
import 'AddActivityPage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedActivityCategory = 'Toutes';
  final CollectionReference activitiesCollection =
  FirebaseFirestore.instance.collection('activite');

  int currentIndex = 0;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Activités'),
        backgroundColor: Colors.white,
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
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenue sur la page des Activités!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    updateSelectedCategory('box');
                  },
                  style: ElevatedButton.styleFrom(
                    primary: selectedActivityCategory == 'box'
                        ? Colors.blueGrey // Active color
                        : Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Box',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    updateSelectedCategory('chess');
                  },
                  style: ElevatedButton.styleFrom(
                    primary: selectedActivityCategory == 'chess'
                        ? Colors.blueGrey // Active color
                        : Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Chess',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    updateSelectedCategory('Toutes');
                  },
                  style: ElevatedButton.styleFrom(
                    primary: selectedActivityCategory == 'Toutes'
                        ? Colors.blueGrey // Active color
                        : Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Toutes',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: (selectedActivityCategory == 'Toutes' ||
                  selectedActivityCategory.isEmpty)
                  ? activitiesCollection.snapshots()
                  : activitiesCollection
                  .where('category', isEqualTo: selectedActivityCategory)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                final List<Activity> firestoreActivities = snapshot.data!.docs
                    .map((doc) {
                  final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                  return Activity(
                    data['category'] ?? '',
                    data['title'] ?? '',
                    data['location'] ?? '',
                    data['image'] ?? '',
                    data['price']?.toDouble() ?? 0.0,
                      data.containsKey('numberofpeople') ? int.tryParse(data['numberofpeople'].toString()) ?? 0 : 0                );
                })
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: firestoreActivities.isNotEmpty
                      ? firestoreActivities.map((selectedActivity) {
                    return InkWell(
                      onTap: () {
                        showDetailsDialog(selectedActivity);
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Titre: ${selectedActivity.title}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Prix: ${selectedActivity.price} EUR',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Lieu: ${selectedActivity.location}',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  InkWell(
                                    onTap: () {
                                      showDetailsDialog(
                                          selectedActivity);
                                    },
                                    child: Text(
                                      'Voir les détails',
                                      style: TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: selectedActivity.image.isNotEmpty
                                  ? Image.network(
                                selectedActivity.image,scale: 1.0,

                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace) {
                                  return Text(
                                      'Erreur de chargement de l\'image');
                                },
                              )
                                  : Container(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList()
                      : [
                    Text(
                      'Aucune activité trouvée pour le nom spécifié : $selectedActivityCategory',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });

          switch (index) {
            case 0:
            // Vous pouvez naviguer vers la page d'activité ou effectuer toute autre action
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddActivityPage()),
              );
              break;
            case 2:
            // Vous pouvez naviguer vers la page de profil ou effectuer toute autre action
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
      ),
    );
  }
  void updateSelectedCategory(String category) {
    setState(() {
      selectedActivityCategory = category;
    });
  }
  void showDetailsDialog(Activity activity) {
    Widget _buildDetailRow(String label, String value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black, // Changer la couleur si nécessaire
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87, // Changer la couleur si nécessaire
            ),
          ),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Détails de l\'activité',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.blue, // Changer la couleur si nécessaire
            ),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              _buildDetailRow('Catégorie:', activity.category),
              SizedBox(height: 12),
              _buildDetailRow('Titre:', activity.title),
              SizedBox(height: 12),
              _buildDetailRow('Lieu:', activity.location),
              SizedBox(height: 12),
              _buildDetailRow(
                  'Participants min:', activity.numberofpeople.toString()),
              SizedBox(height: 12),
              _buildDetailRow('Prix:', activity.price.toString() +' EUR'),
              SizedBox(height: 12),
              _buildDetailRow('Image:', ''),
              SizedBox(height: 8),
              activity.image.isNotEmpty
                  ? Image.network(
                activity.image,
                scale: 1.0,
                height: 200,
                fit: BoxFit.cover,
              )
                  : Container(), // Ajout de la condition pour éviter une erreur si l'image est vide
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Fermer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue, // Changer la couleur si nécessaire
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Activity {
  final String category;
  final String title;
  final String location;
  final String image;
  final double price;
  final int numberofpeople;

  Activity(this.category, this.title, this.location, this.image, this.price,
      this.numberofpeople);
}
