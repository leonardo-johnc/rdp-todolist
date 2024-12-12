import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore db =
      FirebaseFirestore.instance; //new firestore instance
  final TextEditingController nameController =
      TextEditingController(); //captures text from input
  final List<Map<String, dynamic>> tasks = [];

  @override //overrides the init state
  void initState() {
    super.initState();
    fetchTasks(); //calls super so we have access to the constructor, so whenever we reload the phone the tasks persists.
  }

  /*fetch tasks from the firestore 
  and update the local tasks list, so the tasks get saved locally on phone 
  whenever you hot reload or restart the app.*/
  Future<void> fetchTasks() async {
    final snapshot = await db.collection('tasks').orderBy('timestamp').get();

    setState(() {
      tasks.clear();
      tasks.addAll(
        snapshot.docs.map((doc) => {
              'id': doc.id,
              'name': doc.get('name'),
              'completed': doc.get('completed') ??
                  false, /*nullish coalesence,  it handles null or undefined values and checks if it is, and if it is, it will return the 
                  argument on the right
                  */
            }),
      );
    });
  }

  //function that adds new tasks to local state & firestore database

  Future<void> addTask() async {
    /*future -> where it performs the addTask function after the user
                                  input has been taken via the line inside the async block*/
    final taskName = nameController.text
        .trim(); /*captures user input in text form 
                  then it's trimmed to cut white spaces*/

    if (taskName.isNotEmpty) {
      /* this checks if the taskName is not empty (as written, wow! who could've guessed),
                                  if it is not empty(true), it will run the newTask block,
                                   but if its false or empty, it won't run the block.*/
      final newTask = {
        //properties of the task
        'name': taskName,
        'completed': false, //takes in bool values
        'timestamp':
            FieldValue.serverTimestamp(), //records timestamps for the server
      };
      //docRef gives us the insertion id of the task from the database
      final docRef = await db.collection('tasks').add(
          //new firestore instance and tasks is the local state
          newTask); /*add task to database, by calling add 
                      and provides reference to the collection*/

      //adding tasks locally
      setState(() {
        //makes local change
        tasks.add({
          'id': docRef.id, //passes docRef
          ...newTask, //cascading operator (short hand for passing the name, completed, and timestamp)
        });
      });
      nameController.clear(); //clears the text box after adding the task
    }
  }

  //updates the completion status of the tasks in Firestore and locally
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

  //Delete the task locally and in the Firestore
  Future<void> removeTasks(int index) async {
    final task = tasks[index];
    await db.collection('tasks').doc(task['id']).delete();

    setState(() {
      tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 162, 203, 232),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 9, 62, 153),
        ),
        /*iconTheme plays around the toolbar icons
          this changes the color of the hamburger icon
          for the drawer widget*/
        title: Row(
          /*this aligns the children in the widget along its main axis.*/
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              //this widget is wrapping the image widget so it will fill the available space without pixels leaking I suppose
              child: Padding(
                padding: const EdgeInsets.only(right: 15),
                /*adds padding to the right side of the .gif by 15 pixels 
                        making it seem like the .gif moves to the left*/
                child: Image.asset('assets/sui.gif', height: 65),
              ), //image asset that uses my gif
            ),
            const Padding(
              padding: EdgeInsets.only(
                  right:
                      15), //adds padding to the Daily Planner text, but only to the right by 15 pixels
              child: Text(
                'To-Do List',
                style: TextStyle(
                    fontFamily: 'Chicago',
                    fontSize: 24,
                    color: Color.fromARGB(255, 9, 62, 153)),
              ),
            )
          ],
        ),
      ),
      body: Column(
        /*this widget makes the wrapped children to be displayed vertically 
          (also why would you wrap children? that kinda sounds wrong in some ways but we'll roll with it)*/
        children: [
          //man, flutter sure has a lot of children (since flutter likes nesting)
          Expanded(
            child: SingleChildScrollView(
              //makes the view scrollable
              child: Column(
                children: [
                  TableCalendar(
                    // a widget or package that we had to install, it displays the calendar on the app
                    calendarFormat: CalendarFormat
                        .month, //the calendar format is displayed by month
                    focusedDay: DateTime
                        .now(), //this will highlight the current date on the calendar
                    firstDay: DateTime(
                        2024), //this will display the earliest date in the calendar of the current month (Dec 1)
                    lastDay: DateTime(2025),
                    /*this will display the set last day*/
                    calendarStyle: const CalendarStyle(
                      //this lets me style the calendar
                      todayDecoration: BoxDecoration(
                        //this lets me change the highlighted day color to what i want
                        color: Color.fromARGB(255, 162, 203, 232),
                        shape: BoxShape
                            .circle, /*without this, the highlight shape on today's date is square shaped, 
                        i guess that's the default, so to make it circle you need to dictate the shape with BoxShape.circle
                        it has to be circles because we love circles around these parts.*/
                      ),
                      todayTextStyle: TextStyle(
                        /*this allows me to style the text in the calendar widget
                        by adding today on TextStyle, it specifies to change the font color of today's date that's being highlighted*/
                        color: Color.fromARGB(255, 22, 60, 12),
                        fontFamily: 'Chicago',
                      ),
                    ),
                  ),
                  buildTaskList(tasks, removeTasks, updateTask),
                  /*this function has the tasks parameter which it uses to display the task lists */
                ],
              ),
            ),
          ),
          buildAddTaskSection(nameController,
              addTask), /*this function has two arguments the nameController and addTask 
                                                        where the nameController is a TextEditingController from line 16 
                                                        that captures text from the input, while addTask is a future that awaits 
                                                        the user input before adding the task*/
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: const Color.fromARGB(255, 162, 203, 232),
        ),
      ),
    );
  }
}

//build the section for adding text
Widget buildAddTaskSection(nameController, addTask) {
  return Container(
    color: const Color.fromARGB(255, 162, 203, 232),
    child: Padding(
      padding: const EdgeInsets.all(4),
      /*adds padding to the container, 
      i think it dictates the size of the row widget since it's wrapping it*/
      child: Row(
        //this Row widgets wraps the children below to display it horizontally
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 10),
              /*modifies the padding of the text box, top and left specifies only the top and left part of the padding
                                            the value 10 is the pixels of the padding. i did this to align the text box with the button
                                                  as well as to center it*/
              child: TextField(
                maxLength: 36,
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Add Tasks',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(//makes the task input box rounded
                            24),
                  ),
                ),
                style: const TextStyle(
                  //changes the font for inputting tasks
                  fontFamily: 'Chicago',
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 2, left: 3.5, bottom: 5),
            /*this adds padding to the button by using only instead of all, you can specify which sides would be padded*/
            child: RawMaterialButton(
              //a more flexible button widget
              onPressed: addTask, //Adds task when pressed
              fillColor: const Color.fromARGB(
                  255, 23, 55, 109), //color fill of the button
              shape:
                  const CircleBorder(), //i wanted my button to be a circle, this defines the shape of my button
              child: Padding(
                padding: const EdgeInsets.all(12),
                /*adjust the padding of the image asset inside the button
                                                      all 12 means 12 pixels on all sides*/
                child: Image.asset(
                  'assets/suistar.png', //adds my custom icon for the button
                  width: 35, // the dimensions of the image inside my button
                  height: 35,
                ),
              ),
            ),
          ), //
        ],
      ),
    ),
  );
}

//Widget that displays the task item on the UI
Widget buildTaskList(tasks, removeTasks, updateTask) {
  return ListView.builder(
    shrinkWrap:
        true, //this "shrink wraps" the items in the builder to only take up space as its contents
    physics: const NeverScrollableScrollPhysics(),
    /*never scrollable, with that context clue, it makes it that the ListView
                                                    does not let the user to scroll beyond its contents */
    itemCount: tasks.length,
    itemBuilder: (context, index) {
      final task = tasks[index];
      final isEven = index % 2 ==
          0; //alternates the color of the tasks using a modulo operator

      return Padding(
        padding: const EdgeInsets.all(1.0),
        child: ListTile(
          // adds color to the list tiles
          tileColor:
              isEven //the colors set to alternate, when its not even its light blue, and even is light grey
                  ? const Color.fromARGB(255, 162, 203, 232)
                  : const Color.fromARGB(255, 198, 206, 210),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12), //makes the task box edges rounded
          ),
          leading: Icon(
            task['completed'] ? Icons.check_circle : Icons.circle_outlined,
          ),
          title: Text(
            task['name'],
            style: TextStyle(
                decoration:
                    task['completed'] ? TextDecoration.lineThrough : null,
                fontSize: 14,
                fontFamily: 'Chicago',
                color: const Color.fromARGB(255, 9, 62, 153)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: task['completed'], //default value is false
                onChanged: (value) => updateTask(index,
                    value! /*! is a nullable operator, which makes it fail gracefully by not grabbing a value
                              points to a callback function*/
                    ), /*when it gets clicked, it updates the value, points to an async function*/
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => removeTasks(index),
              ),
            ],
          ),
        ),
      );
    },
  );
}
