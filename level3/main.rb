require 'json'

data = JSON.parse(File.read('data.json'))
workers = data['workers']
shifts = data['shifts']
PRICES = {'medic' =>  270, 'interne' => 126}

def count_shift_per_worker(shifts, worker_id)
    shifts.count do |shift|
        shift['user_id'] == worker_id
    end
end

def get_shift_per_worker(shifts, worker_id)
    shifts.select { |shift| shift['user_id'] == worker_id }
end

def get_date_coefficient(date)
    array_date = date.split('-')
    time = Time.new(array_date[0], array_date[1], array_date[2])
    time.saturday? || time.sunday? ? 2 : 1
end

def calculate_wage_per_worker(worker_shifts, worker)
    sum = 0
    worker_shifts.each do |shift|
        sum += get_date_coefficient(shift['start_date']) * PRICES[worker['status']]
    end
    sum
end

def calculate_wages(workers, shifts)
    workers.each do |worker|
        shift_worker = get_shift_per_worker(shifts, worker['id'])
        worker['price'] = calculate_wage_per_worker(shift_worker, worker)
    end
end

def build_worker_list(workers)
    workers.each do |worker|
        worker.select! { |k,v| k == 'id' || k == 'price' }
    end
    return { 'workers' => workers }
end

def store_price_per_user(workers)
    File.open('output_vl.json', 'wb') do |file|
      file.write(JSON.pretty_generate(workers))
    end
end

store_price_per_user(build_worker_list(calculate_wages(workers, shifts)))
