import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:health/health.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTH_NOT_GRANTED
}

class _MyAppState extends State<MyApp> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;
  Random _random = Random.secure();

  @override
  void initState() {
    super.initState();
  }

  Future saveRandomCyclingData() async {
    DateTime randomData =
        DateTime.now().subtract(Duration(days: _random.nextInt(60)));
    HealthFactory health = HealthFactory();
    List<HealthDataType> types = [
      HealthDataType.CYCLING,
    ];

    List<HealthDataPoint> data = [
      HealthDataPoint(
        _random.nextInt(999990),
        types.first,
        HealthDataUnit.METERS,
        DateTime(randomData.year, randomData.month, randomData.day, 13),
        DateTime(randomData.year, randomData.month, randomData.day, 15),
        PlatformType.IOS,
        "",
        activityName: "Health Plugin",
      )
    ];
    print("We will save: $data");

    /// You MUST request access to the data types before reading them
    bool accessWasGranted = await health.requestAuthorization(types);

    if (accessWasGranted) {
      try {
        bool saveResult =
            await health.saveDataQuery(HealthFactory.removeDuplicates(data));
        if (saveResult) {
          print("SAVED: $data");
        }
      } catch (e) {
        print("Caught exception in getHealthDataFromTypes: $e");
      }
    } else {
      print("Authorization not granted");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  Future<void> fetchData() async {
    /// Get everything from midnight until now
    DateTime startDate = DateTime(2020, 11, 07, 0, 0, 0);
    DateTime endDate = DateTime.now();

    HealthFactory health = HealthFactory();

    /// Define the types to get.
    List<HealthDataQuery> types = [
      HealthDataQuery(HealthDataType.STEPS),
      HealthDataQuery(HealthDataType.WEIGHT),
      HealthDataQuery(HealthDataType.HEIGHT),
      HealthDataQuery(HealthDataType.BLOOD_GLUCOSE),
      HealthDataQuery(HealthDataType.CYCLING, 500),
    ];

    setState(() => _state = AppState.FETCHING_DATA);

    /// You MUST request access to the data types before reading them
    bool accessWasGranted = await health
        .requestAuthorization(types.map((e) => e.dataType).toList());

    num steps = 0;

    if (accessWasGranted) {
      try {
        /// Fetch new data
        List<HealthDataPoint> healthData =
            await health.getHealthDataFromTypes(startDate, endDate, types);

        /// Save all the new data points
        _healthDataList.addAll(healthData);
      } catch (e) {
        print("Caught exception in getHealthDataFromTypes: $e");
      }

      /// Filter out duplicates
      _healthDataList = HealthFactory.removeDuplicates(_healthDataList);

      /// Print the results
      _healthDataList.forEach((x) {
        print("Data point: $x");
        steps += x.value;
      });

      print("Steps: $steps");

      /// Update the UI to display the results
      setState(() {
        _state =
            _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
      });
    } else {
      print("Authorization not granted");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  Widget _contentFetchingData() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              strokeWidth: 10,
            )),
        Text('Fetching data...')
      ],
    );
  }

  Widget _contentDataReady() {
    return ListView.builder(
        itemCount: _healthDataList.length,
        itemBuilder: (_, index) {
          HealthDataPoint p = _healthDataList[index];
          return ListTile(
            title: Text("${p.typeString}: ${p.value}"),
            trailing: Text('${p.unitString}'),
            subtitle: Text('${p.dateFrom} - ${p.dateTo}'),
          );
        });
  }

  Widget _contentNoData() {
    return Text('No Data to show');
  }

  Widget _contentNotFetched() {
    return Text('Press the download button to fetch data');
  }

  Widget _authorizationNotGranted() {
    return Text('''Authorization not given.
        For Android please check your OAUTH2 client ID is correct in Google Developer Console.
         For iOS check your permissions in Apple Health.''');
  }

  Widget _content() {
    if (_state == AppState.DATA_READY)
      return _contentDataReady();
    else if (_state == AppState.NO_DATA)
      return _contentNoData();
    else if (_state == AppState.FETCHING_DATA)
      return _contentFetchingData();
    else if (_state == AppState.AUTH_NOT_GRANTED)
      return _authorizationNotGranted();

    return _contentNotFetched();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.file_download),
                onPressed: () {
                  fetchData();
                },
              )
            ],
          ),
          body: Center(
            child: Column(
              children: [
                RaisedButton(
                  child: Text("Add cycling data"),
                  onPressed: () {
                    saveRandomCyclingData();
                  },
                ),
                Container(
                  height: 2,
                  color: Colors.black26,
                ),
                Expanded(child: _content()),
              ],
            ),
          )),
    );
  }
}
