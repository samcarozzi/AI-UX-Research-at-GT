SELECT COUNT(*) FROM song_metadata WHERE quantized_to_sixteenth = 1 AND artist_name LIKE '%Bach%';
SELECT COUNT(*) FROM song_metadata WHERE quantized_to_quarter = 1 AND artist_name LIKE '%Bach%';
SELECT * FROM file_details D, song_metadata M WHERE artist_name LIKE '%Bach%' AND D.file_hash = M.file_hash;

SELECT fd.track_name
FROM file_details fd
JOIN file_genres fg ON fd.file_hash = fg.file_hash
WHERE fg.genre_name = 'classical' 
AND fd.artist_name = 'Bach, Johann Sebastian'
GROUP BY fd.artist_name, fd.track_name;

SELECT fd.track_name
FROM file_details fd
JOIN file_genres fg ON fd.file_hash = fg.file_hash
WHERE fg.genre_name = 'classical' 
AND fd.artist_name = 'Ludwig van Beethoven'
GROUP BY fd.artist_name, fd.track_name;


SELECT fd.track_name
FROM file_details fd
JOIN file_genres fg ON fd.file_hash = fg.file_hash
WHERE fg.genre_name = 'classical' 
AND fd.artist_name = 'Clementi, Muzio'
GROUP BY fd.artist_name, fd.track_name;

UPDATE file_details
SET track_name = SUBSTR(track_name,12)
WHERE artist_name = 'Ludwig van Beethoven'
AND track_name LIKE 'Beethoven%';

SELECT fd.file_hash, fd.file_name, fd.track_name, sm.quantized_to_half, sm.quantized_to_quarter,
       sm.quantized_to_eighth, sm.quantized_to_sixteenth, sm.quantized_to_thirty_second
FROM file_details fd
JOIN song_metadata sm ON fd.file_hash = sm.file_hash
JOIN file_genres fg ON fd.file_hash = fg.file_hash
WHERE fg.genre_name = 'classical'
  AND fd.artist_name = 'Ludwig van Beethoven'
  AND (sm.quantized_to_half = 1 OR sm.quantized_to_quarter = 1 OR sm.quantized_to_eighth = 1 OR 
       sm.quantized_to_sixteenth = 1 OR sm.quantized_to_thirty_second = 1);

SELECT fd.track_name
FROM file_details fd
JOIN song_metadata sm ON fd.file_hash = sm.file_hash
JOIN file_genres fg ON fd.file_hash = fg.file_hash
WHERE fg.genre_name = 'classical'
  AND fd.artist_name = 'Bach, Johann Sebastian'
  AND sm.quantized_to_half = 1;


SELECT fd.track_name
FROM file_details fd
JOIN song_metadata sm ON fd.file_hash = sm.file_hash
JOIN file_genres fg ON fd.file_hash = fg.file_hash
WHERE fg.genre_name = 'classical'
  AND fd.artist_name = 'Bach, Johann Sebastian'
  AND sm.quantized_to_quarter = 1;


SELECT fd.track_name
FROM file_details fd
JOIN song_metadata sm ON fd.file_hash = sm.file_hash
JOIN file_genres fg ON fd.file_hash = fg.file_hash
WHERE fg.genre_name = 'classical'
  AND fd.artist_name = 'Bach, Johann Sebastian'
  AND sm.quantized_to_sixteenth = 1;
