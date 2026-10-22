import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {cityGeocodingQuery} from '../supabase/functions/city-catalog/geocoding.ts';

const cities = JSON.parse(readFileSync(new URL('../assets/data/geonames/cities.json', import.meta.url)));
const labels = JSON.parse(readFileSync(new URL('../assets/data/geonames/countries.json', import.meta.url)));
assert.equal(new Set(cities.map(c => c[0])).size, cities.length, 'Unique source IDs');
assert.equal(new Set(cities.map(c => c[2])).size, cities.length, 'Unique literal keys');
let suffixes = 0;
for (const city of cities) {
  const key = city[2];
  assert.ok(key.length <= 120 && key.length > 0, `Server key bound: ${key}`);
  assert.ok(city[6] && city[10].length > 0, `Zone and aliases present: ${key}`);
  assert.ok(Number.isFinite(city[7]) && Math.abs(city[7]) <= 90, `Latitude: ${key}`);
  assert.ok(Number.isFinite(city[8]) && Math.abs(city[8]) <= 180, `Longitude: ${key}`);
  for (const lang of ['ru','en','be','pl']) {
    assert.ok(labels[lang][city[3]], `Country name: ${city[3]}/${lang}`);
  }
  const address = cityGeocodingQuery(key);
  assert.equal(address, key.replace(/, #\d+$/, ''));
  assert.ok(address.includes(city[3]), `Country retained: ${key}`);
  if (address !== key) suffixes++;
}
assert.ok(suffixes > 0);
assert.equal(cityGeocodingQuery('Минск'), 'Минск, Беларусь');
assert.equal(cityGeocodingQuery('Москва'), 'Москва, Россия');
assert.equal(cityGeocodingQuery('Small settlement, PL'), 'Small settlement, PL');
assert.equal(cityGeocodingQuery('District #12, PL'), 'District #12, PL');
console.log(`PASS: ${cities.length} international keys; ${suffixes} generated ID suffixes stripped; legacy/manual queries retained.`);
console.log(`PASS: source IDs, keys, coordinate bounds, zones/aliases, and country labels; ${new Set(cities.map(c => c[3])).size} countries/territories.`);
