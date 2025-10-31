CREATE OR REPLACE PROCEDURE dim.load_entitygroup2()
 LANGUAGE plpgsql
AS $$
BEGIN

	truncate table dim.EntityGroup;

	insert into dim.EntityGroup (
		entityGroupID
		, EntityGroupName
		, sortorder
		, entitycode
		, entityname
		, entityid
	)

	select distinct 
		 left(b."entity group", charindex(';#', b."entity group") -1)::int EntityGroupID
		, replace(b."entity group", left(b."entity group", charindex('#', b."entity group") ), '') EntityGroupName
		, g.order	SortOrder	
		, e.entitycode::INTEGER as entitycode
		, e.entityname as entityname
		, e.entityid
 from source_sharepoint.Entity_Group_member b
		left outer join source_sharepoint.Entity_Group g on g."entity group name" = right(b."entity group", len(b."entity group") - charindex(';#', b."entity group") - 1) 
		 inner join dim.entity e on e.entityCode = CAST(REGEXP_REPLACE(SPLIT_PART(b.entity, '#', 2), '[^0-9]', '') AS INT)  
	order by 2;


END;
$$
