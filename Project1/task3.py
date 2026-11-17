from fishing import FishingBay

bay = FishingBay(season=1, seed=123)

while not bay.done:
    bay.fish(0)  # Always choose Old Pier

print("Total catch:", bay.total)
print("Best expected catch:", bay.best_possible())
print("True averages:", bay.reveal())