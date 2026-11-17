
import random
import statistics
import csv

from fishing import FishingBay, load_logs, choices, SPOTS


# --------------------------------------------------
# 1. Performance measures
# --------------------------------------------------

def measure_performance(bay):
    averages = bay.reveal()
    expected = 0

    for day, (spot, catch) in enumerate(bay.history, start=1):
        if "means_after_change" in averages and day >= averages["change_day"]:
            expected += averages["means_after_change"][spot]
        else:
            expected += averages["means"][spot]

    optimal = bay.best_possible()

    return {
        "actual": bay.total,
        "expected": expected,
        "optimal": optimal,
        "efficiency": expected / optimal if optimal > 0 else 0,
        "regret": optimal - expected,
        "luck": bay.total - expected
    }


# --------------------------------------------------
# 2. Random strategy
# --------------------------------------------------

def random_strategy(bay, rng):
    while not bay.done:
        spot = rng.randrange(len(SPOTS))
        bay.fish(spot)


# --------------------------------------------------
# 3. Run random simulations
# --------------------------------------------------

def run_random_tests(number_of_bays=500):
    all_results = []

    for season in (1, 2, 3):
        results = []

        for seed in range(number_of_bays):
            bay = FishingBay(season=season, seed=seed)
            rng = random.Random(100000 + seed)

            random_strategy(bay, rng)
            results.append(measure_performance(bay))

        summary = {
            "Season": season,
            "Bays": number_of_bays,
            "Actual": statistics.mean(r["actual"] for r in results),
            "Expected": statistics.mean(r["expected"] for r in results),
            "Optimal": statistics.mean(r["optimal"] for r in results),
            "Efficiency (%)": statistics.mean(r["efficiency"] for r in results) * 100,
            "Regret": statistics.mean(r["regret"] for r in results),
            "Luck": statistics.mean(r["luck"] for r in results),
            "Luck SD": statistics.pstdev(r["luck"] for r in results)
        }

        all_results.append(summary)

        print(f"\nRandom strategy - Season {season}")
        for name, value in summary.items():
            print(f"{name}: {value:.2f}" if isinstance(value, float)
                  else f"{name}: {value}")

    save_csv("random_results.csv", all_results)
    return all_results


# --------------------------------------------------
# 4. Evaluate human players
# --------------------------------------------------

def evaluate_humans(log_folder):
    logs = load_logs(log_folder)
    all_results = []

    for log in logs:
        player = log.get("student_id", "Unknown")

        for season in (1, 2, 3):
            bay = FishingBay.from_log(log, season)
            selected_spots, catches = choices(log, season)

            # Replay the player's choices in the original bay.
            for spot in selected_spots:
                bay.fish(spot)

            result = measure_performance(bay)

            all_results.append({
                "Player": player,
                "Season": season,
                "Actual": result["actual"],
                "Expected": result["expected"],
                "Optimal": result["optimal"],
                "Efficiency (%)": result["efficiency"] * 100,
                "Regret": result["regret"],
                "Luck": result["luck"]
            })

            # Check that replayed catches match the game log.
            if abs(bay.total - sum(catches)) > 0.11:
                print(f"Warning: catch mismatch for {player}, season {season}")

    save_csv("human_results.csv", all_results)

    for result in all_results:
        print(result)

    return all_results


# --------------------------------------------------
# 5. Save results to CSV
# --------------------------------------------------

def save_csv(filename, results):
    if not results:
        print(f"No results to save in {filename}")
        return

    with open(filename, "w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=results[0].keys())
        writer.writeheader()
        writer.writerows(results)

    print(f"\nSaved results to {filename}")


# --------------------------------------------------
# 6. Main program
# --------------------------------------------------

if __name__ == "__main__":

    print("RUNNING RANDOM SIMULATIONS")
    run_random_tests(500)

    print("\nEVALUATING HUMAN PLAYERS")
    evaluate_humans("json-logs")

    print("\nAnalysis complete!")
