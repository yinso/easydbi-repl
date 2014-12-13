# simplest schema updater just runs a series of scripts
# it assumes that these scripts will succeed
# and as long as it keep tracks of the scripts, the schema will be updated approrpiately.

# backup.
# each script will be considered as an unit.
#
# backup/ run upgrade. if error => (or running with transactions - sometimes that can be very expensive!)

