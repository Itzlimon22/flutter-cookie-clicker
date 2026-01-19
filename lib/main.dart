import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Import the Memory Chip

void main() {
  runApp(
    MaterialApp(
      home: MyClickerApp(),
      debugShowCheckedModeBanner: false, // Hides the "Debug" banner
    ),
  );
}

class MyClickerApp extends StatefulWidget {
  @override
  _MyClickerAppState createState() => _MyClickerAppState();
}

class _MyClickerAppState extends State<MyClickerApp> {
  // --- VARIABLES (The Brain) ---
  int score = 0;
  int clickPower = 1; // How many cookies you get per click
  bool isDarkMode = false;

  // The Audio Player
  final player = AudioPlayer();

  // --- FUNCTIONS (The Logic) ---

  // 1. When the App Starts: Load Data
  @override
  void initState() {
    super.initState();
    loadGame();
  }

  // 2. Load Saved Data
  void loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // If "score" exists, load it. If not, start at 0.
      score = prefs.getInt('score') ?? 0;
      clickPower = prefs.getInt('clickPower') ?? 1;
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  // 3. Save Data (We call this whenever data changes)
  void saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('score', score);
    await prefs.setInt('clickPower', clickPower);
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  void increaseScore() {
    // Play Sound
    player.play(AssetSource('crunch.mp3'));

    setState(() {
      score = score + clickPower; // Add current power (1, 2, 5, etc.)
    });
    saveGame(); // Save immediately!
  }

  void resetGame() {
    setState(() {
      score = 0;
      clickPower = 1;
    });
    saveGame();
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    saveGame();
  }

  // This function buys an upgrade!
  void buyUpgrade(int cost, int newPower) {
    if (score >= cost) {
      setState(() {
        score = score - cost; // Pay the price
        clickPower = clickPower + newPower; // Get stronger!
      });
      saveGame();

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upgrade Purchased! Now +$clickPower per click!"),
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Not enough cookies! You need $cost.")),
      );
    }
  }

  // --- THE UI (The Look) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: Text("Cookie Empire"),
        backgroundColor: isDarkMode ? Colors.black : Colors.orange,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: toggleTheme,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Cookies: $score",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              "Power: +$clickPower per click",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 40),

            // THE COOKIE
            GestureDetector(
              onTap: increaseScore,
              child: Image.asset("assets/cookie.png", height: 250),
            ),

            SizedBox(height: 50),

            // BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset Button
                ElevatedButton(
                  onPressed: resetGame,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("RESET"),
                ),
                SizedBox(width: 20),

                // Shop Button
                ElevatedButton(
                  onPressed: () {
                    // Navigate to Shop and pass the "buyUpgrade" function to it!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShopScreen(
                          currentScore: score,
                          currentPower: clickPower,
                          onBuy:
                              buyUpgrade, // Pass the shopping ability to the shop
                        ),
                      ),
                    );
                  },
                  child: Text("SHOP 🛒"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- THE SHOP SCREEN ---
class ShopScreen extends StatelessWidget {
  final int currentScore;
  final int currentPower;
  final Function(int cost, int powerBoost)
  onBuy; // The function to call when buying

  ShopScreen({
    required this.currentScore,
    required this.currentPower,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upgrade Shop"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "You have $currentScore Cookies",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // ITEM 1: GOLDEN OVEN
            Card(
              child: ListTile(
                leading: Icon(Icons.fireplace, color: Colors.orange, size: 40),
                title: Text("Golden Oven"),
                subtitle: Text("Cost: 100 Cookies\nEffect: +1 Click Power"),
                trailing: ElevatedButton(
                  onPressed: () {
                    onBuy(100, 1); // Cost 100, Add 1 Power
                    Navigator.pop(context); // Close shop after buying
                  },
                  child: Text("BUY"),
                ),
              ),
            ),

            SizedBox(height: 10),

            // ITEM 2: DIAMOND HANDS
            Card(
              child: ListTile(
                leading: Icon(Icons.diamond, color: Colors.blue, size: 40),
                title: Text("Diamond Hands"),
                subtitle: Text("Cost: 500 Cookies\nEffect: +5 Click Power"),
                trailing: ElevatedButton(
                  onPressed: () {
                    onBuy(500, 5); // Cost 500, Add 5 Power
                    Navigator.pop(context);
                  },
                  child: Text("BUY"),
                ),
              ),
            ),

            Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close Shop"),
            ),
          ],
        ),
      ),
    );
  }
}
