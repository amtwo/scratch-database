--At the end of every deploy, do a quick sanity check to ensure the metadata in this table is correct.
--This will ensure that we are in a good starting position.
--If there's ever a schema change, we can handle the backfill here, too.
EXEC dbo.Cleanup_ObjectExpiration @Debug = 0;
