INSERT INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`)
VALUES
    ('canteen', 'Canteen', 1, 1, 'item_standard', 1, 'Portable container to carry water'),
    ('wateringcan', 'Water Jug', 10, 1, 'item_standard', 1, 'Bucket of water'),
    ('wateringcan_empty', 'Empty Watering Jug', 10, 1, 'item_standard', 1, 'Empty water bucket'),
    ('bcc_empty_bottle', 'Empty Bottle', 15, 1, 'item_standard', 1, 'Empty bottle'),
    ('bcc_full_bottle', 'Water Bottle', 15, 1, 'item_standard', 1, 'Bottle of water')
ON DUPLICATE KEY UPDATE
    `item` = VALUES(`item`),
    `label` = VALUES(`label`),
    `limit` = VALUES(`limit`),
    `can_remove` = VALUES(`can_remove`),
    `type` = VALUES(`type`),
    `usable` = VALUES(`usable`),
    `desc` = VALUES(`desc`);
