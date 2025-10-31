CREATE OR REPLACE PROCEDURE dim.load_entitygroupmember2()
 LANGUAGE plpgsql
AS $$
BEGIN


-- call dim.load_entitygroupmember2();
-- Select * from dim.EntityGroupmember;

	truncate table dim.EntityGroupmember;

	insert into dim.entityGroupMember (
		entityGroupId
		, entityId
		, entitycode
		, entityname
	)

	select 
       left(gm."entity group", charindex(';#', gm."entity group") -1)::int EntityGroupID,
		e.entityid As entityid,
		e.entitycode::INTEGER As entitycode,
		e.entityname As entityname
	from source_sharepoint.entity_group_member gm
		--inner join source_sharepoint.Entity se on se.ID = left(gm.entity, charindex(';#', gm.entity) -1)
		inner join source_sharepoint.Entity se on se."entity code" = (REGEXP_REPLACE(SPLIT_PART(gm.entity, '#', 2), '[^0-9]', ''))
		inner join dim.entity e on e.EntityCode = se."entity Code"
	;

END;
$$
