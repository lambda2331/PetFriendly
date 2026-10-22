set test.actor='00000000-0000-4000-8000-000000000001';
set test.owner='true';
do $$
declare eid uuid; wid uuid:='00000000-0000-4000-8000-000000000002'; stamp timestamptz;
begin
 eid:=public.create_review60_event('Public walk','Минск',now()+interval '1 day',null,'Europe/Minsk',45);
 if not exists(select 1 from public.events where id=eid and capacity is null and duration=45 and group_id is null) then raise exception 'Creation lost optional fields'; end if;
 begin perform public.create_review60_event('X','Минск',now()+interval '1 day',8,'Europe/Minsk',5); raise exception 'accepted invalid duration'; exception when raise_exception then if sqlerrm='accepted invalid duration' then raise; end if; end;
 begin perform public.create_review60_event('X','Минск',now()+interval '1 day',8,'Europe/Minsk',31); raise exception 'accepted nonstep duration'; exception when raise_exception then if sqlerrm='accepted nonstep duration' then raise; end if; end;
 begin perform public.create_review60_event('X','Минск',now()+interval '1 day',8,'Europe/Minsk',45,'00000000-0000-4000-8000-000000000003'); raise exception 'accepted nonmember'; exception when insufficient_privilege then null; end;
 insert into public.groups values('00000000-0000-4000-8000-000000000003');
 insert into public.group_members values('00000000-0000-4000-8000-000000000003',private.require_actor());
 eid:=public.create_review60_event('Public walk','Минск',now()+interval '1 day',8,'Europe/Minsk',90,'00000000-0000-4000-8000-000000000003','Public note',53.9,27.5,'Park entrance');
 if not exists(select 1 from public.events where id=eid and duration=90 and group_id is not null and latitude=53.9 and location_label='Park entrance') then raise exception 'Atomic venue fields missing'; end if;
 begin perform public.create_review60_event('X','Минск',now()+interval '1 day',8,'Europe/Minsk',45,null,'',91,27); raise exception 'accepted invalid point'; exception when raise_exception then if sqlerrm='accepted invalid point' then raise; end if; end;
 perform set_config('test.owner','false',true);
 begin perform public.create_review60_event('X','Минск',now()+interval '1 day',8,'Europe/Minsk'); raise exception 'accepted helper-only'; exception when insufficient_privilege then null; end;
 insert into public.walk_requests(id,status) values(wid,'assigned');
 update public.walk_requests set status='in_progress' where id=wid;
 select started_at into stamp from public.walk_requests where id=wid;
 if stamp is null then raise exception 'Missing start timestamp'; end if;
 update public.walk_requests set started_at=now()-interval '1 day' where id=wid;
 if (select started_at from public.walk_requests where id=wid)<>stamp then raise exception 'Clock can be overwritten'; end if;
 update public.walk_requests set status='awaiting_confirmation' where id=wid;
 if not exists(select 1 from public.walk_requests where id=wid and finished_at>=started_at) then raise exception 'Missing finish timestamp'; end if;
 if has_function_privilege('anon','public.create_review60_event(text,text,timestamptz,integer,text,integer,uuid,text,double precision,double precision,text)','execute') then raise exception 'Anonymous creation grant'; end if;
end$$;
select 'Review 60 contract assertions passed' as result;
