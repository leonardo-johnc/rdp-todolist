import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final TextEditingController nameController = TextEditingController();
  final FocusNode nameFocusNode = FocusNode(); // Step 1: Define a FocusNode
  final List<Map<String, dynamic>> tasks = [];
  DateTime focusedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchTasks();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      //sets the phone navigation settings
      systemNavigationBarColor:
          Color.fromARGB(255, 0, 0, 0), // Your app background color
      systemNavigationBarIconBrightness:
          Brightness.light, // Adjust icon brightness
    ));
  }

  @override
  void dispose() {
    // Step 1: Dispose of the TextEditingController to free resources.
    nameController.dispose();

    // Step 2: Dispose of the FocusNode to free resources.
    nameFocusNode.dispose();

    // Step 3: Call the superclass' dispose method to clean up any other resources.
    super.dispose();
  }

  Future<void> fetchTasks() async {
    final snapshot = await db.collection('tasks').orderBy('timestamp').get();

    setState(() {
      tasks.clear();
      tasks.addAll(
        snapshot.docs.map((doc) => {
              'id': doc.id,
              'name': doc.get('name'),
              'completed': doc.get('completed') ?? false,
              'timestamp': doc.get('timestamp')?.toDate(),
            }),
      );
    });
  }

  Future<void> addTask() async {
    final taskName = nameController.text.trim();

    if (taskName.isNotEmpty) {
      final newTask = {
        'name': taskName,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final docRef = await db.collection('tasks').add(newTask);

      setState(() {
        tasks.add({
          'id': docRef.id,
          ...newTask,
          'timestamp': DateTime.now(),
        });
      });

      nameController.clear(); // Clear the text field

      // This step ensures the keyboard won't pop up after adding a task
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  Future<void> updateTask(int index, bool completed) async {
    final task = tasks[index];
    await db
        .collection('tasks')
        .doc(task['id'])
        .update({'completed': completed});

    setState(() {
      tasks[index]['completed'] = completed;
    });
  }

  Future<void> removeTasks(int index) async {
    final task = tasks[index];
    await db.collection('tasks').doc(task['id']).delete();

    setState(() {
      tasks.removeAt(index);
    });
  }

  List<Map<String, dynamic>> getFilteredTasks() {
    // The 'tasks' list is filtered to return only the tasks whose timestamps
    // match the currently focused month and year (as determined by 'focusedDate').

    return tasks.where((task) {
      // Using the 'where' method to filter the list of tasks.
      final taskDate = task[
          'timestamp']; // Retrieve the timestamp from each task (expected to be a DateTime object).

      return taskDate !=
              null && // Step 1: Ensure the task has a valid timestamp (not null).

          taskDate.year ==
              focusedDate
                  .year && // Step 2: Check if the year of the task matches the focused date's year.
          taskDate.month ==
              focusedDate
                  .month; // Step 3: Check if the month of the task matches the focused date's month.
    }).toList(); // Convert the filtered iterable into a list and return it.
  }

  void showRenameDialog(BuildContext context, int index) {
    final renameController = TextEditingController(text: tasks[index]['name']);
    final focusNode = FocusNode();

    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename Task"),
          content: TextField(
            controller: renameController,
            decoration: const InputDecoration(labelText: "New Name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                focusNode.unfocus();
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final newName = renameController.text.trim();
                if (newName.isNotEmpty) {
                  await db
                      .collection('tasks')
                      .doc(tasks[index]['id'])
                      .update({'name': newName});

                  setState(() {
                    tasks[index]['name'] = newName;
                  });
                }
                focusNode.unfocus();
                Navigator.of(context).pop();
              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    ).then((_) {
      focusNode.dispose();
    });
  }

  Future<void> showDeleteDialog(BuildContext context, int index) async {
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Task"),
          content: const Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await removeTasks(index);
                Navigator.of(context).pop();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
        /*iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 9, 62, 153),
        ),*/
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 1, right: 20),
                child: Image.asset('assets/calli-peek.gif', height: 70),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Text(
                'To-Do List',
                style: TextStyle(
                    fontFamily: 'Chicago',
                    fontSize: 24,
                    color: Color.fromARGB(255, 220, 98, 143)),
              ),
            )
          ],
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Padding(
                padding: const EdgeInsets.only(left: 1.0),
                child: Image.asset(
                  'assets/calli-logo.png',
                  height: 70,
                  width: 70,
                ),
              ), // Use sui-tetris.png instead
              onPressed: () {
                Scaffold.of(context)
                    .openDrawer(); // This works because the Builder provides the right context
              },
            );
          },
        ),
      ),
      backgroundColor:
          const Color.fromARGB(185, 66, 66, 66), // Set background color here
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TableCalendar(
                    calendarFormat: CalendarFormat.month,
                    focusedDay: focusedDate,
                    firstDay: DateTime(2024),
                    lastDay: DateTime(2026),
                    // Change the style of the month header
                    headerStyle: const HeaderStyle(
                      titleTextStyle: TextStyle(
                        color: Color.fromARGB(
                            255, 255, 255, 255), // Month name text color
                        fontSize: 20, // Font size for the month name
                        fontFamily: 'Chicago', // Use your custom font
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Color.fromARGB(
                            199, 209, 27, 79), // Left chevron color
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Color.fromARGB(
                            199, 209, 27, 79), // Right chevron color
                      ),
                      formatButtonVisible:
                          false, // Hide the "2 weeks" toggle button
                    ),
                    // Change the style of the day headers (weekdays)
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: Color.fromARGB(255, 238, 180,
                            210), // Weekday header color(Mon - Fri)
                        fontFamily: 'Chicago',
                      ),
                      weekendStyle: TextStyle(
                        color: Color.fromARGB(199, 209, 27,
                            79), // Weekend header color(Sat & Sun)
                        fontFamily: 'Chicago',
                      ),
                    ),
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Color.fromARGB(255, 0, 0, 0),
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: TextStyle(
                        color: Color.fromARGB(
                            255, 238, 180, 210), // Regular weekdays text color
                      ),
                      weekendTextStyle: TextStyle(
                        color: Color.fromARGB(
                            199, 209, 27, 79), // Weekend text color
                      ),
                      outsideTextStyle: TextStyle(
                        color: Color.fromARGB(146, 238, 180,
                            210), // Dates outside the current month
                      ),
                      todayTextStyle: TextStyle(
                        color: Color.fromARGB(
                            200, 214, 20, 20), // "Today" date text color
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Chicago', // Use your custom font
                      ),
                      // Holidays styling
                      holidayTextStyle: TextStyle(
                        color: Color.fromARGB(
                            255, 238, 180, 2109), // Holiday text color
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Chicago',
                      ),
                      disabledTextStyle: TextStyle(
                        color: Color.fromARGB(
                            100, 238, 180, 210), // Disabled dates text color
                      ),
                      selectedTextStyle: TextStyle(
                        color: Color.fromARGB(
                            255, 0, 0, 0), // Text color for selected date
                      ),
                    ),
                    // Define your holidays
                    holidayPredicate: (day) {
                      // Return `true` if the day is a holiday
                      final holidays = {
                        DateTime(2024, 12, 25): 'Christmas',
                        DateTime(2025, 1, 1): 'New Year',
                      };
                      return holidays.keys
                          .any((holiday) => isSameDay(holiday, day));
                    },
                    onPageChanged: (date) {
                      setState(() {
                        focusedDate = date;
                      });
                    },
                  ),
                  buildTaskList(getFilteredTasks(), removeTasks, updateTask,
                      showRenameDialog, showDeleteDialog),
                ],
              ),
            ),
          ),
          buildAddTaskSection(context, nameController, addTask),
        ],
      ),
      drawer: Drawer(
        child: GestureDetector(
          behavior: HitTestBehavior
              .opaque, // Ensures taps are registered even on empty spaces
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            color: const Color.fromARGB(211, 0, 0, 0),
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context)
                    .unfocus(); /* Ensures keyboard wont pop up 
                when tapping the gif inside the drawer*/
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Woo-",
                    style: TextStyle(
                      fontFamily: 'Chicago',
                      fontSize: 24,
                      color: Color.fromARGB(255, 220, 98, 143),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context)
                          .unfocus(); // Ensures keyboard won't pop up when tapping the gif inside the drawer
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12),
                      child: Image.asset(
                        'assets/calli-woo.gif',
                        height: 450,
                        width: 450,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAddTaskSection(BuildContext context, nameController, addTask) {
    return Container(
      color: const Color.fromARGB(211, 0, 0, 0),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, left: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                        height:
                            1), // Add some space between the text and the text field
                    TextField(
                      maxLength: 96,
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter new task here...',
                        /* Placeholder, hintstyle implying that it is a "hint" 
                            text inside the text field where it takes in user input*/
                        hintStyle: TextStyle(
                          fontFamily: 'Chicago', // Use the same font as before
                          fontSize: 16,
                          color: Color.fromARGB(108, 238, 180, 210),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Chicago',
                        fontSize: 16,
                        color: Color.fromARGB(186, 251, 185, 219),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 2, left: 3.5, bottom: 5),
              child: RawMaterialButton(
                onPressed: () {
                  FocusScope.of(context).unfocus(); // Dismiss the keyboard
                  addTask();
                },
                fillColor: const Color.fromARGB(255, 0, 0, 0),
                shape: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    'assets/death-sensei.png',
                    width: 45,
                    height: 45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTaskList(
      tasks, removeTasks, updateTask, showRenameDialog, showDeleteDialog) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];

        // Get the task's timestamp and calculate the difference
        final taskDate = task['timestamp'] as DateTime;
        final currentDate = DateTime.now();
        final difference = currentDate.difference(taskDate).inDays;

        // Determine the appropriate image to use
        String imagePath;
        if (difference >= 2) {
          // If 2 or more days old
          imagePath = task['completed']
              ? 'assets/calli-spin.gif'
              : 'assets/calli-flushed.gif';
        } else {
          // If less than 2 days old
          imagePath = task['completed']
              ? 'assets/calli-spin.gif'
              : 'assets/calli-idle.gif';
        }

        return Padding(
          padding: const EdgeInsets.all(1),
          child: ListTile(
            tileColor: task['completed']
                ? const Color.fromARGB(255, 215, 131, 174)
                : const Color.fromARGB(210, 77, 76, 76),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 4),
              child: Image.asset(
                imagePath, // Use the determined image path
                width: 70.0,
                height: 70.0,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                task['name'],
                style: TextStyle(
                  decoration: task['completed']
                      ? TextDecoration.combine([
                          TextDecoration.lineThrough,
                          TextDecoration.lineThrough
                        ])
                      : null,
                  decorationColor: const Color.fromARGB(185, 0, 0, 0),
                  decorationThickness: 15,
                  fontSize: 16,
                  fontFamily: 'Chicago',
                  color: task['completed']
                      ? const Color.fromARGB(255, 215, 131, 174)
                      : const Color.fromARGB(255, 215, 131, 174),
                ),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Color.fromARGB(255, 238, 180, 2109),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task['timestamp'] != null
                        ? task['timestamp'].toString().split(' ')[0]
                        : "",
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    color: const Color.fromARGB(200, 214, 20, 20),
                    onPressed: () => showRenameDialog(context, index),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: IconButton(
                    icon: const Icon(Icons.delete),
                    color: const Color.fromARGB(200, 214, 20, 20),
                    onPressed: () => showDeleteDialog(context, index),
                  ),
                ),
              ],
            ),
            onTap: () => updateTask(index, !task['completed']),
          ),
        );
      },
    );
  }
}
