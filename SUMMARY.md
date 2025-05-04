SUMMARY
## Entities
# User: Represents a player, with an isActive status.
# Match: Represents a match event, containing a list of players.
# GameResult: Represents the outcome of a single game within a match, involving 4 players.
# UserMatchResult: A key association table:
    Links a User to a Match and a possible GameResult.
    This allows you to track which matches a user has participated in and which game results are 
    associated with a user in a match.

## Operations
# Add a player to a match:
    Add the player to the Match's list of players.
    Create a UserMatchResult entry linking the User and the Match.
    Set the User's isActive status to true.
# Remove a player from a match:
    Remove the player from the Match's list of players.
    Remove the UserMatchResult entry linking the User and the Match.
    Crucially: Remove any UserMatchResult entries that link the User to any GameResult within that Match. This ensures that orphaned game results are not left behind.
    Check if the User is associated with any other Match in the UserMatchResult table. If not, set the User's isActive status to false.
# Add a game result:
    Create a GameResult.
    Create UserMatchResult entries linking each of the 4 Players in the GameResult to the GameResult.
# Delete a game result:
    Remove the GameResult.
    Remove the UserMatchResult entries linking the Players to the GameResult.
