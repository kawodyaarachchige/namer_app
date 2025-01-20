import 'package:english_words/english_words.dart';// Package for generating random word pairs.
import 'package:flutter/material.dart';// Package for building UI elements.
import 'package:provider/provider.dart';// Package for managing app state.

void main() {
  runApp(MyApp()); // Entry point of the application.
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Using ChangeNotifierProvider to manage app state.
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Builder(
        builder: (context) {
          final appState = context.watch<MyAppState>(); // Watches for state changes.
          return MaterialApp(
            title: 'Namer App',
            theme: ThemeData(
              useMaterial3: true,
              // Dynamic theme based on light/dark mode.
              colorScheme: ColorScheme.fromSeed(
                seedColor: appState.isDarkMode
                    ? Colors.pink.shade700
                    : Colors.pink.shade300,
                brightness: appState.isDarkMode
                    ? Brightness.dark
                    : Brightness.light,
              ),
            ),
            home: MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random(); // Current random word pair.
  var history = <WordPair>[]; // List to maintain the history of word pairs.
  GlobalKey? historyListKey; // Key to manage the animated list state.
  var favorites = <WordPair>[]; // List to store favorite word pairs.
  bool isDarkMode = false; // Flag for light/dark mode.

  void toggleDarkMode() {
    // Toggles between light and dark mode.
    isDarkMode = !isDarkMode;
    notifyListeners(); // Notifies listeners to rebuild UI.
  }

  void getNext() {
    // Clear the animated list before adding a new word.
    _clearAnimatedList();

    // Insert the current word pair into history.
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0); // Animate the addition of the new item.

    // Generate a new random word pair.
    current = WordPair.random();
    notifyListeners();
  }

  void toggleFavorite([WordPair? pair]) {
    // Toggles the favorite status of a word pair.
    pair = pair ?? current;
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    // Removes a word pair from favorites.
    favorites.remove(pair);
    notifyListeners();
  }

  void clearHistory() {
    // Clears the history list with animation.
    _clearAnimatedList();
    notifyListeners();
  }

  void _clearAnimatedList() {
    // Private method to clear the animated list with fade-out effect.
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    while (history.isNotEmpty) {
      animatedList?.removeItem(
        0,
        (context, animation) {
          return FadeTransition(
            opacity: animation,
            child: ListTile(
              title: Text(history[0].asLowerCase),
            ),
          );
        },
      );
      history.removeAt(0); // Remove each item from the history list.
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0; // Index to manage navigation.

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var colorScheme = Theme.of(context).colorScheme;

    Widget page; // Determines which page to display.
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage(); // Home page with word pair generator.
        break;
      case 1:
        page = FavoritesPage(); // Favorites page.
        break;
      default:
        throw UnimplementedError('No widget for $selectedIndex');
    }

    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200), // Smooth page transitions.
        child: page,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Namer App'),
        actions: [
          IconButton(
            icon: Icon(appState.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: appState.toggleDarkMode, // Toggles light/dark mode.
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adaptive UI based on screen width.
          if (constraints.maxWidth < 450) {
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                  child: BottomNavigationBar(
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.favorite),
                        label: 'Favorites',
                      ),
                    ],
                    currentIndex: selectedIndex,
                    onTap: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                )
              ],
            );
          } else {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 600,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.favorite),
                        label: Text('Favorites'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
                Expanded(child: mainArea),
              ],
            );
          }
        },
      ),
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon = appState.favorites.contains(pair)
        ? Icons.favorite
        : Icons.favorite_border;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView(), // Displays the history list.
          ),
          SizedBox(height: 10),
          BigCard(pair: pair), // Displays the current word pair.
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite(); // Toggles favorite.
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext(); // Generates the next word pair.
                },
                child: Text('Next'),
              ),
            ],
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: appState.clearHistory, // Clears the history.
            child: Text('Clear History'),
          ),
          Spacer(flex: 2),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String searchQuery = ''; // Tracks the search query.

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    var filteredFavorites = appState.favorites
        .where((pair) => pair.asLowerCase.contains(searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Favorites',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value; // Updates the search query.
              });
            },
          ),
        ),
        Expanded(
          child: filteredFavorites.isEmpty
              ? Center(child: Text('No favorites found.')) // Displays if empty.
              : ListView(
                  children: [
                    for (var pair in filteredFavorites)
                      ListTile(
                        title: Text(pair.asLowerCase),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            appState.removeFavorite(pair); // Removes favorite.
                          },
                        ),
                      )
                  ],
                ),
        ),
      ],
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    Key? key,
    required this.pair,
  }) : super(key: key);

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          '${pair.first} ${pair.second}', // Displays the word pair.
          style: style,
        ),
      ),
    );
  }
}

class HistoryListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return ListView.builder(
      itemCount: appState.history.length,
      itemBuilder: (context, index) {
        var pair = appState.history[index];
        return ListTile(
          title: Text(pair.asLowerCase), // Displays each word pair.
        );
      },
    );
  }
}
