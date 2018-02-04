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

def calculate_wage_per_worker(nb_shifts, worker)
    p PRICES[worker['status']]
    nb_shifts * PRICES[worker['status']]
end

def calculate_wages(workers, shifts)
    workers.each do |worker|
        worker['price'] = calculate_wage_per_worker(count_shift_per_worker(shifts, worker['id']), worker)
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
