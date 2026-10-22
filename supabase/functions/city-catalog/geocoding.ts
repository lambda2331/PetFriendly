const knownBy = ['Минск','Гродно','Брест','Гомель','Витебск','Могилёв','Бобруйск','Барановичи','Борисов','Пинск','Орша','Новополоцк','Лида','Солигорск','Мозырь','Полоцк','Молодечно','Жлобин','Речица','Слуцк','Жодино','Кобрин'];
    const knownRu = ['Москва', 'Санкт-Петербург', 'Казань', 'Нижний Новгород', 'Ростов-на-Дону', 'Краснодар', 'Воронеж', 'Сочи', 'Смоленск', 'Калининград', 'Самара', 'Саратов', 'Екатеринбург', 'Уфа', 'Пермь', 'Челябинск', 'Тюмень', 'Омск', 'Новосибирск', 'Красноярск', 'Томск', 'Иркутск', 'Якутск', 'Владивосток', 'Хабаровск', 'Магадан', 'Петропавловск-Камчатский', 'Анадырь'];
export function cityGeocodingQuery(city: string): string {
  // GeoNames IDs distinguish stable app keys; they are not address text.
  // Keep the stored key intact and strip only the final generated suffix.
  const address = city.replace(/, #\d+$/, '');
  return knownBy.includes(address) ? `${address}, Беларусь` : knownRu.includes(address) ? `${address}, Россия` : address;
}
