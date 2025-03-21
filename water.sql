INSERT INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`)
VALUES
    ('canteen', 'Canteen', 1, 1, 'item_standard', 1, 'A portable container to carry water.'),
    ('wateringcan', 'Water Jug', 10, 1, 'item_standard', 1, 'A bucket of water.'),
    ('wateringcan_empty', 'Empty Watering Jug', 10, 1, 'item_standard', 1, 'An empty water bucket.'),
    ('bcc_empty_bottle', 'Empty Bottle', 15, 1, 'item_standard', 1, 'An empty bottle.'),
    ('bcc_full_bottle', 'Water Bottle', 15, 1, 'item_standard', 1, 'A bottle of water.')
ON DUPLICATE KEY UPDATE
    `item` = VALUES(`item`),
    `label` = VALUES(`label`),
    `limit` = VALUES(`limit`),
    `can_remove` = VALUES(`can_remove`),
    `type` = VALUES(`type`),
    `usable` = VALUES(`usable`),
    `desc` = VALUES(`desc`);
