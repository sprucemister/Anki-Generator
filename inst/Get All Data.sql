SELECT 
	c.id AS id_card
	, flds AS fields
	, sfld AS sort_field
	, CASE 
			WHEN type = 0 THEN 'new' 
			WHEN type = 1 THEN 'learning'
			WHEN type = 2 THEN 'review'
			WHEN type = 3 THEN 'relearning'
			END AS type
	, CASE  
		  WHEN queue=-3 THEN 'user buried'
		  WHEN queue=-2 THEN 'buried'
		  WHEN queue=-1 THEN 'suspended'
		  WHEN queue=0 THEN 'new' 
		  WHEN queue=1 THEN 'learning'
		  WHEN queue=2 THEN 'review' --(as for type)
		  WHEN queue=3 THEN 'learning' --, next rev in at least a day after the previous review
		  WHEN queue=4 THEN 'preview'
		  END AS queue
	, due
	, ivl AS interval
	, reps
	, d.name AS deck
FROM notes n 
JOIN cards c ON c.nid=n.id 
JOIN decks d ON d.id=c.did
ORDER BY type
;
