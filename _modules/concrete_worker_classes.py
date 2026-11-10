#!/usr/bin/env python


def compute(workers, global_conf=None, numofworkers=None):
    if isinstance(global_conf, dict):
        base_worker_class = global_conf.get("WORKER_CLASS", "")
    elif isinstance(global_conf, str):
        base_worker_class = global_conf
    else:
        base_worker_class = ""

    concrete_slots = set()
    if numofworkers:
        try:
            concrete_slots.update(range(1, int(numofworkers) + 1))
        except (ValueError, TypeError):
            pass

    for sec_id in workers.keys():
        if isinstance(sec_id, int):
            concrete_slots.add(sec_id)
        elif isinstance(sec_id, str) and sec_id.isdigit():
            concrete_slots.add(int(sec_id))

    slot_classes = {slot: base_worker_class for slot in concrete_slots}

    for sec_id, details in workers.items():
        if not isinstance(details, dict):
            continue
        new_class = details.get("WORKER_CLASS")
        append_class = details.get("WORKER_CLASS+")
        if new_class is None and append_class is None:
            continue

        target_slots = set()
        for part in str(sec_id).split(","):
            part = part.strip()
            if "-" in part:
                bounds = part.split("-", 1)
                if bounds[0].strip().isdigit() and bounds[1].strip().isdigit():
                    start, end = int(bounds[0].strip()), int(bounds[1].strip())
                    for slot in concrete_slots:
                        if start <= slot <= end:
                            target_slots.add(slot)
            elif part.isdigit():
                slot = int(part)
                if slot in concrete_slots:
                    target_slots.add(slot)

        for slot in target_slots:
            if new_class is not None:
                slot_classes[slot] = new_class
            if append_class is not None:
                current = slot_classes[slot]
                slot_classes[slot] = (
                    f"{current},{append_class}" if current else append_class
                )

    result = {}
    for slot, classes in slot_classes.items():
        result[slot] = classes
        result[str(slot)] = classes
    return result
