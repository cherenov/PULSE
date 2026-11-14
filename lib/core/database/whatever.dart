import 'dart:math';

Map<DateTime, double> randomDataListGenerator(
  Map<DateTime, double> randomData,
  int currentIteration,
  int dayAmount,
  int measurefrequency,
  double averageValue,
  double incrementMagnitude,
  DateTime startDate,
) {
  final random = Random();
  int numberOfMeasurements = (dayAmount * 24 / measurefrequency).toInt();
  bool bigIncrement = false;

  for (int i = currentIteration; i < numberOfMeasurements; i++) {
    if (random.nextDouble() * 100 > 80 && !bigIncrement) {
      return randomDataListGeneratorWithTrend(
        randomData,
        i,
        dayAmount,
        measurefrequency,
        averageValue,
        incrementMagnitude,
        startDate,
      );
    }
    bigIncrement = false;

    double randomIncrement = random.nextDouble() * incrementMagnitude;

    if (random.nextDouble() * 100 > 50) {
      randomIncrement = randomIncrement * (-1);
    }

    if (random.nextDouble() * 100 > 80) {
      randomIncrement = randomIncrement * 10;
    }

    double randomValue = (averageValue + randomIncrement).roundToDouble();
    DateTime measurementTime = startDate.add(
      Duration(hours: i * measurefrequency),
    );
    randomData[measurementTime] = randomValue;
  }
  return randomData;
}

Map<DateTime, double> randomDataListGeneratorWithTrend(
  Map<DateTime, double> randomData,
  int currentIteration,
  int dayAmount,
  int measurefrequency,
  double averageValue,
  double incrementMagnitude,
  DateTime startDate,
) {
  final random = Random();
  int numberOfMeasurements = (dayAmount * 24 / measurefrequency).toInt();
  bool negativeTrend = random.nextDouble() * 100 >= 50;

  for (int i = currentIteration; i < numberOfMeasurements; i++) {
    if (random.nextDouble() * 100 > 80) {
      return randomDataListGenerator(
        randomData,
        i,
        dayAmount,
        measurefrequency,
        averageValue,
        incrementMagnitude,
        startDate,
      );
    }

    double randomIncrement = random.nextDouble() * incrementMagnitude / 2.0;

    if (random.nextDouble() * 100 > 20 && negativeTrend) {
      randomIncrement = randomIncrement * (-1);
    } else if (random.nextDouble() * 100 > 80 && !negativeTrend) {
      randomIncrement = randomIncrement * (-1);
    }

    double randomValue = (averageValue + randomIncrement).roundToDouble();
    if (randomData.isNotEmpty) {
      randomValue = (randomData.values.last + randomIncrement).roundToDouble();
    }
    DateTime measurementTime = startDate.add(
      Duration(hours: i * measurefrequency),
    );
    randomData[measurementTime] = randomValue;
  }
  return randomData;
}
