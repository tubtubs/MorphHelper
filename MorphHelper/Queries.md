Morphs: 
```
select unique creature_template.display_id1, spell_template.name
from spell_template
join creature_template on creature_template.entry = spell_template.effectMiscValue1 
where spell_template.effectApplyAuraName1 = 56
```

Mounts:
```
select unique creature_template.display_id1, spell_template.name
from spell_template
join creature_template on creature_template.entry = spell_template.effectMiscValue1 
where spell_template.effectApplyAuraName1 = 78
```
