# Dart Solutions for Advent of Code 2025

[Advent of Code 2025](https://adventofcode.com/2025).

This repository contains my solutions to the Advent of Code 2025 challenges, implemented in Dart. Each day's challenge is organized in its own directory under `bin/calendar/dec_XX.dart`, where `XX` represents the day of the month.

## Getting Started

- Clone the repository:
  ```bash
  git clone https://github.com/zeyus/aoc2025.git
  cd aoc2025
  ```
- Ensure you have Dart installed. You can download it from [dart.dev](https://dart.dev/get-dart).
- Install dependencies:
  ```bash
  dart pub get
  ```
- Run a specific day's solution:
  ```bash
  dart bin/advent_of_code_2025.dart -d 1 # For Day 1
  ```

## Building

If you want to run a compiled verision of the project, just run:

```bash
dart build cli -o build
```
This will create a `build/` directory with the compiled files.

Then you would run it from your terminal like so:

```bash
./build/bundle/bin/advent_of_code_2025 -d 1
```

## Project Structure

- `bin/calendar/dec_XX.dart`: Contains the solution for Day XX.
- `bin/common/`: Contains a registry, Matrix2D.
- `bin/resources/`: Contains input files for each day's challenge.
  - Due to the author Eric Wastl's [preferences](https://adventofcode.com/2025/about#faq_copying), the input files are not included, you can download them from the Advent of Code website.
  - Input files are expected to be named as `dec_XX_input.txt` (where XX is the day number, e.g. 01).

## Solutions

| Day | Code                                    | AOC Link                                       | Stars  |
|----:|-----------------------------------------|------------------------------------------------|:------:|
| 1   | [dec_01.dart](bin/calendar/dec_01.dart) | [Day 1](https://adventofcode.com/2025/day/1)   | \* \*     |
| 2   | [dec_02.dart](bin/calendar/dec_02.dart) | [Day 2](https://adventofcode.com/2025/day/2)   | \* \*     |
| 3   | [dec_03.dart](bin/calendar/dec_03.dart) | [Day 3](https://adventofcode.com/2025/day/3)   | \* \*     |
| 4   | [dec_04.dart](bin/calendar/dec_04.dart) | [Day 4](https://adventofcode.com/2025/day/4)   | \* \*     |
| 5   | [dec_05.dart](bin/calendar/dec_05.dart) | [Day 5](https://adventofcode.com/2025/day/5)   | \* \*     |
| 6   | [dec_06.dart](bin/calendar/dec_06.dart) | [Day 6](https://adventofcode.com/2025/day/6)   | \* \*     |
| 7   | [dec_07.dart](bin/calendar/dec_07.dart) | [Day 7](https://adventofcode.com/2025/day/7)   | \* \*     |
| 8   | [dec_08.dart](bin/calendar/dec_08.dart) | [Day 8](https://adventofcode.com/2025/day/8)   | \* \*     |
| 9   | [dec_09.dart](bin/calendar/dec_09.dart) | [Day 9](https://adventofcode.com/2025/day/9)   | \* \*[^a] |
| 10  | [dec_10.dart](bin/calendar/dec_10.dart) | [Day 10](https://adventofcode.com/2025/day/10) | \*[^b]    |
| 11  | [dec_11.dart](bin/calendar/dec_11.dart) | [Day 11](https://adventofcode.com/2025/day/11) | \*[^c]    |
| 12  | [dec_12.dart](bin/calendar/dec_12.dart) | [Day 12](https://adventofcode.com/2025/day/12) | -[^d]     |

[^a]: I solved part 1 no problems, but I needed a bit of help with part 2 after trying and failing a bunch of times.
[^b]: Only part 1 solved. Part 2 test passes, but obviously my solution is not anywhere near efficient enough.
[^c]: Part two theoretically works, but in practice it takes too long.
[^d]: Did not start.


## Contributing

Not accepting contributions, this is just for fun, and you're welcome to compare my solutions with your own, but I want to solve it myself :)
